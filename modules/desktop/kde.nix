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
    isoimagewriter
    kate
    kcalc
    kdeconnect-kde
    kompare
#   krohnkite
    partitionmanager
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
