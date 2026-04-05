{ config, pkgs, ... }:

{
    fileSystems."/mnt/trading" = {
    device = "192.168.1.5:/mnt/user/trading";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };

    fileSystems."/mnt/media" = {
    device = "192.168.1.5:/mnt/user/media-server/media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };

    fileSystems."/mnt/home" = {
    device = "192.168.1.5:/mnt/user/home";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };

    fileSystems."/mnt/paperless" = {
    device = "192.168.1.5:/mnt/user/paperless";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };

    fileSystems."/mnt/backup" = {
    device = "192.168.1.5:/mnt/user/backup";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noatime"
    ];
  };

#    fileSystems."/mnt/setup" = {
#    device = "192.168.1.5:/mnt/user/setup";
#    fsType = "nfs";
#    options = [
#      "x-systemd.automount"
#      "x-systemd.idle-timeout=600"
#      "_netdev"
#      "noatime"
#    ];
#  };
}
