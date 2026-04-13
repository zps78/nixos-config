# ../../modules/kde.nix
{ config, pkgs, lib, ... }:

{
  # Desktop & Display Manager
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE apps
  environment.systemPackages = with pkgs.kdePackages; [
    isoimagewriter
    kate
    kdeconnect-kde
    kompare
    partitionmanager
   # xdg-desktop-portal-kde
  ];

    # KDE portal (FIX for Plex + Electron apps)
xdg.portal = {
  enable = true;

  extraPortals = [
    pkgs.xdg-desktop-portal-kde
  ];

  config = {
    common.default = "kde";
  };
};

  # Optional: KDE-specific programs
  programs.kdeconnect.enable = true;

  # Fingerprint GUI settings for KDE: false still allows fingerprint for sudo
  security.pam.services.kde.fprintAuth = false;

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
