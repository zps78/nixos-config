# ../../modules/desktop/kde.nix
{ config, pkgs, lib, ... }:

{
  # Desktop & Display Manager
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE apps
  environment.systemPackages = with pkgs.kdePackages; [
    isoimagewriter
    merkuro
    kate
    kcalc
    kdeconnect-kde
    kompare
#   krohnkite
    partitionmanager
  ];

    # KDE portal (FIX for Plex + Electron apps)
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config.common.default = "kde";
  };

  # Optional: KDE-specific programs
  programs.kdeconnect.enable = true;

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
