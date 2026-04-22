# ../../modules/apps/core.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  # Core CLI tools
#    agenix
    btop
    iperf3
    fio
    pciutils
    rclone
    rsync
    usbutils
    wget

  # Networking
    arp-scan
#    eddie
    ethtool
    nfs-utils

  # Multimedia
    audacity
    bambu-studio
#    clipgrab
    darktable
    ffmpeg-full
    gimp
    handbrake
    krita
    losslesscut-bin
    mkvtoolnix
    plex-desktop
    spotify
    vlc

  # Utilities
    ddrescue
    ddrescueview
    ddrutility
    scrcpy
    testdisk
    remmina
  ];
}
