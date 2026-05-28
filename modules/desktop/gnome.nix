# ../../modules/desktop/gnome.nix
{ config, pkgs, lib, ... }:

{
  # X11/Wayland base
  services.xserver.enable = true;

  # Display manager
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # GNOME desktop
  services.desktopManager.gnome.enable = true;

  # dconf is required for GNOME settings
  programs.dconf.enable = true;

  # GNOME keyring
  services.gnome.gnome-keyring.enable = true;

  # Polkit authentication dialogs
  security.polkit.enable = true;

  # Portal integration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
    ];

    config = {
      common = {
        default = [ "gnome" "gtk" ];
      };
    };
  };

  # Useful GNOME additions
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    extension-manager
  ];
}
