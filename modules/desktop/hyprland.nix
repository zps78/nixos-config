# ../../modules/desktop/fonts.nix
{ config, pkgs, lib, ... }:

{
  # Hyprland owns the Wayland compositor session.
  # Keep this file mutually exclusive with modules/desktop/kde.nix.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # Keep this on for legacy app compatibility.
  };

  # SDDM is the login manager for the Hyprland host profile.
  # Don't also enable Plasma in the same host configuration.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # Useful for a cleaner Wayland login path.
  };

  # Portal backend for Hyprland.
  # This is where Wayland app integration happens, so keep it here and
  # avoid also setting KDE portal defaults in the same host.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
    ];

    # Default portal selection for Wayland apps.
    # If you later add a second desktop profile, this is a key place to check.
    config.common.default = lib.mkDefault [ "hyprland" "gtk" ];
  };

  # Helpful desktop services for a Hyprland session.
  # These are fine here because they support file browsing, power profiles,
  # and common desktop app behavior.
  services.gvfs.enable = true;
  services.power-profiles-daemon.enable = true;

  # Desktop integration helpers.
  programs.dconf.enable = true;
  security.polkit.enable = true;

  # Wayland session environment variables.
  # These are session-level, so keep them out of shared system modules unless
  # you want them to apply to every desktop session.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SDL_VIDEODRIVER = "wayland,x11";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # Hyprland desktop package set.
  # This is intentionally desktop-focused: bar, launcher, notifications,
  # screenshots, clipboard, theming, media control, and Wayland support.
  environment.systemPackages = with pkgs; [
    waybar
    rofi
    swaynotificationcenter
    hyprpaper
    hyprlock
    hypridle
    hyprsunset

    libnotify
    dolphin
    loupe
    alacritty

    wl-clipboard
    cliphist

    grim
    slurp
    swappy

    pavucontrol
    playerctl

    networkmanagerapplet
    blueman

    brightnessctl
    imagemagick
    nwg-look

    qt5.qtwayland
    qt6.qtwayland
  ];
}
