# ../../modules/desktop/niri.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myDesktop.stack == "niri") {
  ############################################################
  # Niri compositor (system-level enablement)
  ############################################################

  programs.niri.enable = true;

  ############################################################
  # Display / login manager
  ############################################################

  # Use greetd (lightweight and Wayland-friendly)
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --user-menu --cmd niri-session";
    };
  };

  ############################################################
  # Authentication / permissions
  ############################################################

  # Required for screen locking, polkit auth prompts, etc.
  security.polkit.enable = true;

  # PAM rule for swaylock (Super+Alt+L default keybind)
  security.pam.services.swaylock = {};

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
#   swaybg                   # Wallpaper tool for Wayland compositors
#   swayidle                 # Idle management daemon for Wayland
#   swaylock                 # Screen locker for Wayland
    xwayland-satellite       # Xwayland outside your Wayland compositor
  ];

  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

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
