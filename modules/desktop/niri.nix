# modules/desktop/niri.nix
# Niri scrollable-tiling Wayland compositor for krugerrand.
# Enable with: imports = [ ../../modules/desktop/niri.nix ];
# Do NOT import alongside kde.nix or gnome.nix.
{ pkgs, ... }:

{
  # Niri is in nixpkgs since ~24.11; no extra flake needed
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --user-menu --cmd niri";
    };
  };

  # Required for screen locking, polkit auth prompts, etc.
  security.polkit.enable = true;

  # PAM rule for swaylock (Super+Alt+L default keybind)
  security.pam.services.swaylock = {};

  # Secret service (used by e.g. Chromium, VSCode)
  services.gnome.gnome-keyring.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;

  # XWayland support via xwayland-satellite (niri integrates it automatically)
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    swaylock        # screen locker
    swayidle        # idle/DPMS management
    mako            # notification daemon
    swaybg          # wallpaper setter
    fuzzel          # app launcher (Super+D default)
    alacritty       # terminal (Super+T default)
    waybar          # status bar
    brightnessctl   # laptop brightness keys
    playerctl       # media keys
    wl-clipboard    # wl-copy / wl-paste
    grim slurp      # screenshot (grim + region selector)
  ];

  # Needed for portals (screen share, file pickers)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config = {
      common.default = [ "gtk" ];
      niri.default = [ "gtk" "gnome" ];
      niri."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      niri."org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
  };

  # Udev rules already handled by programs.niri.enable, but make sure
  # the user is in the video/input groups (usually set in your common.nix)
  # users.users.zp.extraGroups = [ "video" "input" ];
}
