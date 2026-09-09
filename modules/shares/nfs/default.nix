# ../../modules/shares/nfs/default.nix
#
# NFS client + NAS mounts (all NFSv4).
#
# Per-host, per-share opt-in:
#
#   myShares = {
#     nfs-media.enable    = true;
#     nfs-torrents.enable = true;
#   };
#
# The NAS is reached at its LAN IP. A Tailscale subnet router advertising
# 192.168.1.0/24 makes that IP reachable off-LAN as well.

{ config, lib, ... }:

let
  nasHost = "192.168.1.5";

  # share name -> export path on the NAS
  exports = {
    nfs-backup    = "/mnt/user/backup";
    nfs-home      = "/mnt/user/home";
    nfs-media     = "/mnt/user/media-server/media";
    nfs-paperless = "/mnt/user/paperless";
    nfs-torrents  = "/mnt/user/media-server/torrents/complete";
    nfs-trading   = "/mnt/user/trading";
  };

  mountPoint = name: "/mnt/" + lib.removePrefix "nfs-" name;

  # Mounts are `hard` (the default, kept on purpose): a process blocks
  # until the NAS returns rather than getting EIO mid-write.
  mountOptions = [
    "x-systemd.automount"          # mount on first access, not at boot
    "x-systemd.idle-timeout=300"   # unmount after 5 min idle
    "x-systemd.device-timeout=10s"
    "x-systemd.mount-timeout=10s"  # bound how long an access blocks if NAS is down
    "x-systemd.requires=network-online.target"
    "x-systemd.after=network-online.target"
    "x-systemd.after=tailscaled.service"   # ordering only; matters off-LAN via the subnet route
    "_netdev"
    "nofail"
    "hard"
    "noatime"
    "tcp"
    "nconnect=8"                   # parallel connections (NFSv4.1)
    "rsize=1048576"
    "wsize=1048576"
    "timeo=600"
    "retrans=2"
    "async"
  ];

  enabledExports = lib.filterAttrs (n: _: config.myShares.${n}.enable) exports;
in
{
  options.myShares = lib.mapAttrs
    (name: _: {
      enable = lib.mkEnableOption "NAS ${lib.removePrefix "nfs-" name} share (NFSv4)";
    })
    exports;

  config = lib.mkIf (enabledExports != { }) {
    boot.supportedFilesystems.nfs = true;

    fileSystems = lib.mapAttrs'
      (name: export:
        lib.nameValuePair (mountPoint name) {
          device = "${nasHost}:${export}";
          fsType = "nfs4";
          options = mountOptions;
        })
      enabledExports;
  };
}
