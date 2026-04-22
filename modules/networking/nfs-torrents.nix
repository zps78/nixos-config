# ../../modules/networking/nfs-torrents.nix
{ config, pkgs, ... }:

{
  fileSystems."/mnt/torrents" = {
    device = "192.168.1.5:/mnt/user/media-server/torrents/complete";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "_netdev"
      "noatime"
      "tcp"
      "rsize=1048576"
      "wsize=1048576"
      "timeo=600"
      "retrans=2"
      "async"
    ];
  };
}
