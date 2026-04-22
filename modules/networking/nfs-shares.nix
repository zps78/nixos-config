# ../../modules/nfs-shares.nix
{ config, pkgs, ... }:

{
  fileSystems."/mnt/trading" = {
    device = "192.168.1.5:/mnt/user/trading";
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

  fileSystems."/mnt/media" = {
    device = "192.168.1.5:/mnt/user/media-server/media";
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

  fileSystems."/mnt/home" = {
    device = "192.168.1.5:/mnt/user/home";
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

  fileSystems."/mnt/paperless" = {
    device = "192.168.1.5:/mnt/user/paperless";
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

  fileSystems."/mnt/backup" = {
    device = "192.168.1.5:/mnt/user/backup";
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

#  fileSystems."/mnt/setup" = {
#    device = "192.168.1.5:/mnt/user/setup";
#    fsType = "nfs";
#    options = [
#      "x-systemd.automount"
#      "_netdev"
#      "noatime"
#      "tcp"
#      "rsize=1048576"
#      "wsize=1048576"
#      "timeo=600"
#      "retrans=2"
#      "async"
#    ];
#  };
}
