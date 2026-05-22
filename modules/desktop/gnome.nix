# ../../modules/desktop/gnome.nix
{ config, pkgs, lib, ... }:

{
  # Desktop & Display Manager
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GNOME services
  services.gnome.gnome-keyring.enable = true;

  # Portal integration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
    ];

    config.common.default = "gnome";
  };

  # Required by many GNOME settings/apps
  programs.dconf.enable = true;

  # Polkit authentication dialogs
  security.polkit.enable = true;

  # Useful GNOME additions
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    extension-manager
  ];
}
