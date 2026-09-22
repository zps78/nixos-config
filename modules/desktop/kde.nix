# ../../modules/desktop/kde.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myDesktop.stack == "kde") {
  ############################################################
  # KDE Plasma desktop
  ############################################################

  services.xserver.enable = lib.mkDefault true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.settings.General.Numlock = "on";

  ############################################################
  # XDG Portal stack (CRITICAL for Sunshine)
  ############################################################

  xdg.portal = {
    enable = true;

    xdgOpenUsePortal = true;

    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];

    config.common.default = "kde";
  };

  ############################################################
  # KDE apps
  ############################################################

  # ark, okular, gwenview, ffmpegthumbs, dolphin: already in plasma6's own
  # optionalPackages (installed by default unless excluded); kdegraphics-
  # thumbnailers is in requiredPackages (always installed, can't even be
  # excluded) - nothing to add here for any of those, confirmed against
  # nixpkgs' plasma6.nix module source.
  environment.systemPackages = with pkgs.kdePackages; [
    isoimagewriter    # Program to write hybrid ISO files onto USB disks
    kcalc             # Calculator offering everything a scientific calculator does, and more
    kompare           # Graphical File Differences Tool
    partitionmanager  # Manage the disk devices, partitions and file systems on your computer
    filelight         # Quickly visualize your disk space usage
  ];

  ############################################################
  # Optional UI defaults
  ############################################################

  environment.etc."xdg/kdeglobals".text = ''
  [General]
  ColorScheme=BreezeDark

  [KDE]
  LookAndFeelPackage=org.kde.breezedark.desktop

  [Icons]
  Theme=breeze-dark

  [UiSettings]
  ColorScheme=BreezeDark
  '';
}
