# ../../modules/desktop/niri.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myDesktop.stack == "niri") {
  ############################################################
  # Niri compositor (system-level enablement)
  ############################################################

  programs.niri = {
    enable = true;
  };

  ############################################################
  # Display / login manager
  ############################################################

  programs.noctalia-greeter = {
    enable = true;
    settings = {
      appearance.scheme = "Synced";
      appearance.hide_logo = true;
    };
  };

  ############################################################
  # Authentication / permissions
  ############################################################

  # Required for screen locking, polkit auth prompts, etc.
  security.polkit.enable = true;

  # Secret service (used by e.g. Chromium, VSCode)
  services.gnome.gnome-keyring.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;

  ############################################################
  # XDG portals (IMPORTANT: only define defaults here ONCE)
  ############################################################

  # Needed for portals (screen share, file pickers)
  xdg.portal = {
    enable = true;
    
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # IMPORTANT:
    # Use mkDefault so KDE/GNOME modules can override cleanly if needed
    config.common.default = lib.mkDefault "gtk";
  };

  ############################################################
  # System packages required for Niri sessions
  ############################################################

  #  via xwayland-satellite (niri integrates it automatically)
  environment.systemPackages = with pkgs; [
    xwayland-satellite       # Xwayland outside your Wayland compositor
    polkit_gnome
  ];

  environment.pathsToLink = [
    "share/thumbnailers"
  ];

  environment.sessionVariables = {
    XDG_SESSION_DESKTOP = "niri";
  };

  # Udev rules already handled by programs.niri.enable, but make sure
  # the user is in the video/input groups (usually set in your common.nix)
  # users.users.zp.extraGroups = [ "video" "input" ];
}
