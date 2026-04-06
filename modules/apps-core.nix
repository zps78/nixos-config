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
    nfs-utils

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

    thunderbird

    # Utilities
    ddrescue
    ddrescueview
    ddrutility
    scrcpy
    testdisk

    # Office
    thunderbird

    # Optional extras
#    papirus-icon-theme
  ];
}
