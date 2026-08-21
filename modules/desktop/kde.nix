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
#      xdg-desktop-portal-gtk   # important fallback for capture sessions
    ];

    config.common.default = "kde";
  };

  ############################################################
  # KDE apps
  ############################################################

  environment.systemPackages = with pkgs.kdePackages; [
    isoimagewriter           # Program to write hybrid ISO files onto USB disks
    kate
    kcalc                    # Calculator offering everything a scientific calculator does, and more
    kdeconnect-kde           # Multi-platform app that allows your devices to communicate
    kompare                  # Graphical File Differences Tool
    partitionmanager         # Manage the disk devices, partitions and file systems on your computer

#    ark                      # File archiver by KDE
#    dolphin                  # File manager by KDE
#    ffmpegthumbs             # FFmpeg-based thumbnail creator for video files
#    filelight                # Quickly visualize your disk space usage
#    gwenview                 # Image viewer by KDE
#    kdegraphics-thumbnailers # Thumbnailers for various graphics file formats
#    okular                   # KDE document viewer
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

  # home.nix
#  programs.plasma.configFile = {
#    "kcminputrc".Mouse.naturalScrolling = true;
#    "kcminputrc".Touchpad.naturalScrolling = true;
#  };
}
