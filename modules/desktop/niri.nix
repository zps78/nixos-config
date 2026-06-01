# modules/desktop/niri.nix
# Niri scrollable-tiling Wayland compositor for krugerrand.
# Enable with: imports = [ ../../modules/desktop/niri.nix ];
# Do NOT import alongside kde.nix or gnome.nix.
{ pkgs, lib, ... }:

{
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
      command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --user-menu --cmd niri";
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
#     xdg-desktop-portal-gnome
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
    swaylock                 # Screen locker for Wayland
    swayidle                 # Idle management daemon for Wayland
    mako                     # Lightweight Wayland notification daemon
    swaybg                   # Wallpaper tool for Wayland compositors
    alacritty                # Cross-platform, GPU-accelerated terminal emulator (Super+T default)
    brightnessctl            # This program allows you read and control device brightness
    playerctl                # Command-line utility and library for controlling media players that implement MPRIS
    wl-clipboard             # Command-line copy/paste utilities for Wayland
    grim                     # Grab images from a Wayland compositor
    slurp                    # Select a region in a Wayland compositor
    noctalia-shell           # Sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell
  ];

  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
  };

  # Udev rules already handled by programs.niri.enable, but make sure
  # the user is in the video/input groups (usually set in your common.nix)
  # users.users.zp.extraGroups = [ "video" "input" ];
}
