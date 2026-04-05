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
#    rsync
    usbutils
    wget

    # Networking
    arp-scan
#    eddie
    nfs-utils
    rclone

    # Media
    audacity
    bambu-studio
#    clipgrab
    darktable
    ffmpeg-full
    gimp
    handbrake
    losslesscut-bin
    mkvtoolnix
    plex-desktop
    spotify
    vlc

    # Virtualization / Emulation
    libvirt
    moonlight-qt
    virt-manager
    waydroid
    winetricks
    wineWow64Packages.staging

    # GUI apps
    brave
    filezilla
#    googleearth-pro
    kdePackages.kate
    kdePackages.kompare
    thunderbird
    remmina

    # Utilities
    ddrescue
    ddrescueview
    ddrutility
    scrcpy
    teamviewer
    testdisk

    # Office
    onlyoffice-desktopeditors
    thunderbird
    xournalpp

    # Optional extras
#    papirus-icon-theme
  ];
}
