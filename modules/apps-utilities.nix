{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core CLI tools

    # Networking
    arp-scan
#    eddie
    rclone

    gimp
    libvirt
    virt-manager
    waydroid
    winetricks
    wineWow64Packages.staging

    # Utilities
    ddrescue
    ddrescueview
    ddrutility
    scrcpy
    testdisk

  ];
}
