# modules/kde.nix
{ config, pkgs, lib, ... }:

{
  # Desktop & Display Manager
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE apps
  environment.systemPackages = lib.filter (p: p != pkgs.kdeApplications.kwrite) [
    pkgs.kdeApplications.kate
    pkgs.kdeApplications.kdeconnect
    pkgs.kdeApplications.kompare
  ];

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
};
