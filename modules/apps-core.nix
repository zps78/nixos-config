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

    # Virtualization / Emulation
    libvirt
    moonlight-qt
    virt-manager
    # Wine
    winetricks
    wineWow64Packages.staging
    #    waydroid

    # Internet
#    eddie
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
    moonlight-qt
    remmina

    # Office
    onlyoffice-desktopeditors
    xournalpp
    # Optional extras
#    papirus-icon-theme
  ];
}
