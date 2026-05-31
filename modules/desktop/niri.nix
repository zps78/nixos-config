# modules/desktop/niri.nix
{ pkgs, ... }:

{
  ############################################################
  # Display manager
  ############################################################

  services.xserver.enable = true;

  # Keep SDDM initially
  services.displayManager.sddm.enable = true;

  ############################################################
  # Niri
  ############################################################

  programs.niri.enable = true;

  ############################################################
  # XDG Portal stack
  ############################################################

  xdg.portal = {
    enable = true;

    xdgOpenUsePortal = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    config.common.default = "gtk";
  };

  ############################################################
  # Authentication
  ############################################################

#  security.polkit.enable = true;
services.gnome.gcr-ssh-agent.enable = false;
  ############################################################
  # Desktop integration
  ############################################################

#  programs.dconf.enable = true;

#  services.gnome.gnome-keyring.enable = true;

  ############################################################
  # Applications
  ############################################################

  environment.systemPackages = with pkgs; [
    ghostty
    fuzzel
    wl-clipboard
    xwayland-satellite

    kdePackages.kate
    kdePackages.partitionmanager
    kdePackages.kdeconnect-kde
    kdePackages.kcalc
    kdePackages.kompare
  ];

  programs.kdeconnect.enable = true;
}
