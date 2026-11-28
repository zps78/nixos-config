# ../../hosts/kraken/array.nix
#
# The media array and its helpers (since the move from karma, 2026-11-27):
#
#   scratch   T500 500GB, pool "scratch" at /mnt/scratch - downloads in
#             progress and freshly finished (qBittorrent seeds them 7 days,
#             the arrs import by copy). No snapshots: temporary data.
#   parity    Exos 16TB ZL2MZHEP, XFS at /mnt/parity1 - SnapRAID parity for
#             the media datasets of disk1-5 (each disk is a single-disk ZFS
#             pool from Unraid; ZFS detects corruption, SnapRAID repairs it
#             and rebuilds a dead disk). One data entry per disk: only
#             /mnt/diskN/media-server (photos-array and the stale home/trading
#             copies on disk2-4 aren't covered - a second entry on the same
#             disk would break the recovery maths).
#   scrubs    rpool/games/vault/scratch monthly (modules/storage), disk1-5
#             quarterly (user's decision 2026-11-25), each with a
#             healthchecks.io check and the ntfy summary.
#
# One-time setup (MOVE-DAY.md): the scratch pool and the parity filesystem
# are created by hand, then a first `snapraid sync` (long: ~33 TB).
{ config, lib, pkgs, ... }:

let
  disks = [ "disk1" "disk2" "disk3" "disk4" "disk5" ];
in
{
  # ── scratch ─────────────────────────────────────────────────────────
  myStorage.zfs.extraPools = [ "scratch" ];
  fileSystems."/mnt/scratch" = {
    device = "scratch";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-scratch.service" "x-systemd.after=zfs-import-scratch.service" ];
  };
  systemd.tmpfiles.rules = [ "d /var/lib/snapraid 0755 root root -" ]
    ++ map (d: "d /mnt/scratch/${d} 0775 media users -") [
      "torrents" "torrents/incomplete" "torrents/complete" "usenet"
    ];

  # ── parity + SnapRAID ───────────────────────────────────────────────
  fileSystems."/mnt/parity1" = {
    device = "/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL2MZHEP-part1";
    fsType = "xfs";
    options = [ "nofail" "noatime" ];
  };

  services.snapraid = {
    enable = true;
    parityFiles = [ "/mnt/parity1/snapraid.parity" ];
    dataDisks = lib.listToAttrs (lib.imap1 (i: d: lib.nameValuePair "d${toString i}" "/mnt/${d}/media-server") disks);
    # content files: the system SSD + two data disks (outside the data paths)
    contentFiles = [ "/var/lib/snapraid/snapraid.content" "/mnt/disk1/snapraid.content" "/mnt/disk2/snapraid.content" ];
    # downloads and work folders change all the time and are re-downloadable
    # (they also made the first sync warn about files changing under it)
    exclude = [ "*.unrecoverable" "/lost+found/" ".Trash-*/" "*.!qB" "*.part" "/.zfs/"
                "/torrents/" "/usenet/" "/downloads/" "/handbrake/" "/unmanic/" "/youtube-dl/" ];
    sync.interval = "01:00";                                     # daily
    scrub = { interval = "Mon *-*-* 02:00:00"; plan = 8; olderThan = 10; };   # weekly, 8% of the oldest
  };
  # SnapRAID needs the disks and parity mounted - never run against bare
  # mountpoints (it would treat a missing disk as "all files deleted")
  systemd.services.snapraid-sync.unitConfig.RequiresMountsFor = [ "/mnt/parity1" ] ++ map (d: "/mnt/${d}/media-server") disks;
  systemd.services.snapraid-scrub.unitConfig.RequiresMountsFor = [ "/mnt/parity1" ] ++ map (d: "/mnt/${d}/media-server") disks;

  # ── scrubs: monthly for the rest, quarterly for the media disks ──────
  services.zfs.autoScrub.pools = [ "rpool" "games" "vault" "scratch" ];
  systemd.services.zfs-scrub-media = {
    description = "ZFS scrub of the media disks (quarterly)";
    serviceConfig.Type = "oneshot";
    path = [ config.boot.zfs.package ];
    script = "zpool scrub -w ${lib.concatStringsSep " " disks}";   # waits until all five are done
    onSuccess = [ "zfs-scrub-report.service" ];
  };
  systemd.timers.zfs-scrub-media = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "*-01,04,07,10-15 03:30:00"; Persistent = true; RandomizedDelaySec = "1h"; };
  };

  # ── spin-down ───────────────────────────────────────────────────────
  # The media disks + parity (Exos 16TB) and the unused 2TB pair sleep
  # after 30 min idle (-S 241). vault's 4TB WD40EFRX mirrors stay spinning:
  # they hold the live /srv data. Anything polling SMART must skip drives in
  # standby (smartd -n standby in modules/services/alerts.nix, scrutiny's
  # metrics_smart_args) or it wakes them again.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]*", ENV{DEVTYPE}=="disk", ENV{ID_MODEL}=="ST16000NM001G*|WDC_WD20EFRX*", RUN+="${pkgs.hdparm}/bin/hdparm -S 241 /dev/%k"
  '';
  services.scrutiny.collector.settings.commands.metrics_smart_args = "--xall --json -n standby";

  # Storage tile on Homepage: one "Media array" line + its own scrub date
  myStorage.statusApi.arrayPools = disks;

  myServices.alerts.failureUnits = [ "snapraid-sync" "snapraid-scrub" "zfs-scrub-media" ];
  myServices.alerts.healthchecks.checks = {
    snapraid-sync = "kraken-snapraid-sync";      # daily
    snapraid-scrub = "kraken-snapraid-scrub";    # weekly
    zfs-scrub-media = "kraken-scrub-media";      # quarterly
  };

  environment.systemPackages = [ pkgs.xfsprogs pkgs.snapraid ];
}
