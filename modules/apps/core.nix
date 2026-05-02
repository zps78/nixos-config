# ../../modules/apps/core.nix
{ config, pkgs, ... }:

{
  programs.thunderbird.enable = true;
  environment.systemPackages = with pkgs; [
  # Core CLI tools
#    agenix
    btop
    iperf3
    fio
    git
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

    thunderbird

  # Multimedia
    audacity
    bambu-studio
#    clipgrab
    ffmpeg-full
    gimp
    handbrake
    krita
    losslesscut-bin
    mkvtoolnix
    vlc

  # Utilities
    ddrescue
    ddrescueview
    ddrutility
    testdisk
  ];
}
