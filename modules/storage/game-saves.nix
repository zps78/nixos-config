# ../../modules/storage/game-saves.nix
#
# Backup of game saves (and the Lutris/Steam setup around them) from the
# games SSD to another pool. The games pool is a single SSD without
# snapshots (games re-download); saves don't. Checked every `interval`
# (default 6 h), but the target pool is only touched when something
# changed since the last run (the check reads just the SSD - HDDs that
# spun down stay down). Then an
# rsync of only what matters into `target`, and a ZFS snapshot of
# `dataset` (the history: one per play session, the newest keepSnapshots):
#
#   prefixes/<game>/users/      each Wine prefix's users folder (AppData,
#                               Documents, Saved Games, Goldberg/RUNE saves)
#   games/<game>/...SaveGames/  save folders inside game folders (Unreal
#                               games like Black Myth: Wukong keep them there)
#   setup/                      Lutris game configs + database, Steam
#                               shortcuts/artwork - to rebuild the library
#
# Caches, logs, temp files and shader caches are skipped. Restore: copy
# back from /srv/gamesaves/.zfs/snapshot/<snapshot>/... (hidden dir - type
# the path, snapshots are named saves-<date>-<time>) or from the live copy.
{ config, lib, pkgs, ... }:

let
  cfg = config.myStorage.gameSaves;
  user = config.myDesktop.sessionUser;
  home = config.users.users.${user}.home;

  stamp = "/var/lib/game-saves-backup/last-run";

  sync = pkgs.writeShellScript "game-saves-backup" ''
    set -uo pipefail
    export PATH=${lib.makeBinPath [ pkgs.rsync pkgs.coreutils pkgs.findutils pkgs.util-linux config.boot.zfs.package ]}
    T=${cfg.target}

    # Nothing played since the last backup? Then don't touch the target
    # pool at all (HDDs may be spun down) - the check reads only the games
    # SSD and the stamp on the system disk.
    if [ -e ${stamp} ]; then
      changed=$(find ${cfg.prefixes}/*/pfx/drive_c/users ${cfg.games} \
                     ${home}/.config/lutris ${home}/.local/share/lutris/pga.db \
                     ${home}/.local/share/Steam/userdata \
                     -newer ${stamp} -type f -print -quit 2>/dev/null)
      [ -n "$changed" ] || { echo "nothing changed since $(date -r ${stamp} '+%F %H:%M') - skipped"; exit 0; }
      echo "changed since last run, e.g. $changed"
    fi

    mountpoint -q "$T" || { echo "$T is not mounted - nothing copied"; exit 1; }
    touch ${stamp}.new                             # changes from now on count for the next run
    R="rsync -a --delete --delete-excluded --prune-empty-dirs"
    X=(
      --exclude='Temp/' --exclude='INetCache/' --exclude='Microsoft/' --exclude='Logs/'
      --exclude='*.log' --exclude='GLCache/' --exclude='shadercache/' --exclude='*shaderprecache'
      --exclude='.sentry-native/' --exclude='CrashReportClient/' --exclude='Desktop/'
      --exclude='Downloads/' --exclude='Favorites/' --exclude='Links/' --exclude='Music/'
      --exclude='Pictures/' --exclude='Videos/' --exclude='Contacts/' --exclude='Searches/'
    )
    rc=0
    mkdir -p "$T/prefixes" "$T/games" "$T/setup"

    # 1. each prefix's users folder
    for p in ${cfg.prefixes}/*/; do
      g=$(basename "$p"); u="$p/pfx/drive_c/users"
      [ -d "$u" ] || continue
      mkdir -p "$T/prefixes/$g"                    # rsync creates only the last path component
      $R "''${X[@]}" "$u/" "$T/prefixes/$g/users/" || rc=1
    done

    # 2. save folders inside game folders (Unreal: <Game>/<proj>/Saved/SaveGames*)
    # (process substitution, not a pipe: the loop must set rc in this shell)
    while IFS= read -r -d "" d; do
      rel=''${d#${cfg.games}/}
      mkdir -p "$T/games/$(dirname "$rel")"
      $R "$d/" "$T/games/$rel/" || rc=1
    done < <(find ${cfg.games} -mindepth 2 -maxdepth 4 -type d -name 'SaveGames*' \
               -not -path '${cfg.prefixes}/*' -not -path '*/_saves/*' -print0 2>/dev/null)

    # 3. the setup around the saves (Lutris + Steam shortcuts/artwork)
    for s in ${home}/.config/lutris/games ${home}/.local/share/lutris/games \
             ${home}/.local/share/lutris/pga.db ${home}/.local/share/lutris/coverart \
             ${home}/.local/share/lutris/banners; do
      [ -e "$s" ] || continue
      dst="$T/setup/lutris/''${s#${home}/}"; mkdir -p "$(dirname "$dst")"
      $R "$s" "$(dirname "$dst")/" || rc=1
    done
    for c in ${home}/.local/share/Steam/userdata/*/config; do
      [ -d "$c" ] || continue
      id=$(basename "$(dirname "$c")")
      mkdir -p "$T/setup/steam/$id"
      $R --include='shortcuts.vdf' --include='grid/***' --exclude='*' "$c/" "$T/setup/steam/$id/" || rc=1
    done

    echo "game saves backed up to $T ($(du -sh "$T" | cut -f1))"
    [ $rc = 0 ] || exit $rc

    # History: one snapshot per backup that actually ran (only after
    # playing), the newest ${toString cfg.keepSnapshots} kept. Own snapshots instead of sanoid's
    # hourly ones - those would wake the target pool every hour.
    zfs snapshot "${cfg.dataset}@saves-$(date +%Y%m%d-%H%M)" || exit 1
    zfs list -H -t snapshot -o name -s creation -d 1 ${cfg.dataset} | grep '@saves-' |
      head -n -${toString cfg.keepSnapshots} | xargs -r -n1 zfs destroy
    mv ${stamp}.new ${stamp}
  '';
in
{
  options.myStorage.gameSaves = {
    enable = lib.mkEnableOption "regular backup of game saves to another pool (only after something changed)";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "6h";
      description = "How often to check for changed saves (the check reads only the games SSD; the target pool is touched only when something changed).";
    };

    games = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/games/nonsteam";
      description = "Folder with the installed (non-Steam) games.";
    };
    prefixes = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/games/nonsteam/_prefixes";
      description = "Folder with one Wine/Proton prefix per game.";
    };
    target = lib.mkOption {
      type = lib.types.str;
      example = "/srv/gamesaves";
      description = "Mounted backup target (a ZFS dataset on other disks).";
    };
    dataset = lib.mkOption {
      type = lib.types.str;
      example = "vault/gamesaves";
      description = "The ZFS dataset mounted at target - the job snapshots it after each backup.";
    };
    keepSnapshots = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "How many backup snapshots (one per backup that ran, i.e. per play session) to keep.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.game-saves-backup = {
      description = "Back up game saves from the games SSD";
      after = [ "local-fs.target" ];
      unitConfig.RequiresMountsFor = [ cfg.target ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = sync;
        Nice = 10;
        IOSchedulingClass = "idle";
        # Reads the session user's home (0700) - root, but sandboxed:
        # everything read-only except the target.
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.target ];
        StateDirectory = "game-saves-backup";    # the "last run" stamp, on the system disk
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
    systemd.timers.game-saves-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = cfg.interval;
        RandomizedDelaySec = "2min";
        Persistent = true;
      };
    };
  };
}
