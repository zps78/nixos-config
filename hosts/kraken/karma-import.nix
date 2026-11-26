# ../../hosts/kraken/karma-import.nix
#
# TEMPORARY (karma -> kraken migration, 2026-11). Delete this file and its
# import once karma is retired.
#
# karma's shares, mounted read-only over NFS (karma exports them to the LAN
# with no_root_squash, so root here reads everything with owners intact),
# and `karma-copy`, a one-shot that mirrors them onto kraken:
#
#   sudo systemctl start karma-copy        # runs in the background
#   journalctl -fu karma-copy              # progress per share
#
# Re-runnable: a second run only transfers changes and mirrors deletions
# (--delete) - the final sync on move day, with karma's containers stopped,
# so databases (Plex, Immich's Postgres, the arrs) land consistent.
#
# Destinations (datasets created by hand, legacy mounts in
# hardware-configuration.nix): home, trading, backup, setup, photos on
# vault; appdata into /srv/appdata/karma (NVMe) as a staging area the
# services take their data from. Not here: media-server (comes on its
# disks), photos-array (stays on its disk), domains (not exported).
{ config, lib, pkgs, ... }:

let
  karma = "192.168.1.5";
  # share on karma -> destination on kraken
  copies = {
    home    = "/srv/home";
    trading = "/srv/trading";
    backup  = "/srv/backup";
    setup   = "/srv/setup";
    photos  = "/srv/photos";
    appdata = "/srv/appdata/karma";
  };
in
{
  boot.supportedFilesystems.nfs = true;

  # mounted on first access, unmounted after 10 idle minutes; read-only
  fileSystems = lib.mapAttrs' (share: _: lib.nameValuePair "/mnt/karma/${share}" {
    device = "${karma}:/mnt/user/${share}";
    fsType = "nfs";
    options = [ "ro" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"
                "x-systemd.mount-timeout=30" "nofail" "soft" "timeo=600" "retrans=3" ];
  }) copies;

  systemd.services.karma-copy = {
    description = "Copy karma's shares to kraken (migration, re-runnable)";
    after = [ "network-online.target" "zfs-import-vault.service" ];
    wants = [ "network-online.target" ];
    # every destination must be its real (mounted) dataset, never a bare dir
    unitConfig.RequiresMountsFor = lib.attrValues copies;
    # a rebuild must never restart (or stop) a running copy - and a
    # restarted oneshot makes nixos-rebuild wait until it has finished,
    # i.e. hours (2026-11-26). Script changes apply at the next manual start.
    restartIfChanged = false;
    stopIfChanged = false;
    path = [ pkgs.rsync pkgs.coreutils pkgs.util-linux ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
    script = lib.concatStrings (lib.mapAttrsToList (share: dest: ''
      echo "== ${share} -> ${dest}  ($(date '+%F %T'))"
      ls /mnt/karma/${share}/ >/dev/null    # trigger the automount
      mountpoint -q /mnt/karma/${share} || { echo "karma's ${share} isn't mounted - skipped" >&2; exit 1; }
      mkdir -p ${dest}
      # -aHAX: owners, perms, hardlinks, ACLs, xattrs; --numeric-ids keeps
      # karma's 99:100 etc. as numbers
      # exit 24 = some source files vanished during the run - normal while
      # karma's containers are live (temp files, logs); anything else fails
      rc=0; rsync -aHAX --numeric-ids --delete --info=stats1 /mnt/karma/${share}/ ${dest}/ || rc=$?
      if [ "$rc" = 24 ]; then echo "(${share}: some files vanished during the copy - fine on a live copy)";
      elif [ "$rc" != 0 ]; then echo "rsync failed on ${share} (exit $rc)" >&2; exit "$rc"; fi
      echo "== ${share} done ($(date '+%F %T')), $(du -sh ${dest} | cut -f1) on kraken"
    '') copies);
  };
}
