# ../../modules/apps-core.nix
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
    eddie
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

  # Internet
    brave
    filezilla
#    googleearth-pro
    thunderbird

  # Utilities
    ddrescue
    ddrescueview
    ddrutility
    scrcpy
    testdisk
    remmina
    # Remote access

  # Office
    onlyoffice-desktopeditors
    xournalpp
  ];
}
