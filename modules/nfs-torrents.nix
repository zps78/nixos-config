{ config, pkgs, ... }:

{
    fileSystems."/mnt/torrents" = {
    device = "192.168.1.5:/mnt/user/media-server/torrents/complete";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };
}
