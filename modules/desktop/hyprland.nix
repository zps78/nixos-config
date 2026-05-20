# ../../modules/desktop/hyprland.nix
#
# Hyprland desktop module (ML4W-inspired, NixOS-native)
#
# Provides:
# - Hyprland Wayland compositor
# - SDDM login manager
# - PipeWire audio stack
# - Portal integration
# - Modern Wayland UX stack (bar, launcher, notifications)
# - Theming + color pipeline support
#

{ config, pkgs, ... }:

{
  # -------------------------------------------------
  # Hyprland (Wayland compositor)
  # -------------------------------------------------
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # -------------------------------------------------
  # Display manager
  # -------------------------------------------------
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # -------------------------------------------------
  # XDG Portals (critical for Wayland)
  # -------------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
    ];
  };

  # -------------------------------------------------
  # Essential desktop services
  # -------------------------------------------------
  services = {
    gvfs.enable = true;                 # file manager / MTP / trash
    power-profiles-daemon.enable = true;
  };

  programs.dconf.enable = true;

  # -------------------------------------------------
  # Security / system UX
  # -------------------------------------------------
  security.polkit.enable = true;

  # -------------------------------------------------
  # Wayland session environment
  # -------------------------------------------------
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SDL_VIDEODRIVER = "wayland,x11";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # -------------------------------------------------
  # Core Wayland / Hyprland applications
  # -------------------------------------------------
  environment.systemPackages = with pkgs; [

    # Core ML4W-like stack
    waybar
    rofi-wayland
    swaynotificationcenter
    hyprpaper
    hyprlock
    hypridle
    hyprsunset

    # Wallpaper / theming / color pipeline
    swww
    matugen
    pywal

    # Notifications + UX
    libnotify

    # File manager
    dolphin
    loupe

    # Terminal
    alacritty

    # Clipboard tools
    wl-clipboard
    cliphist

    # Screenshots / screen tools
    grim
    slurp
    grimblast
    swappy

    # Audio control
    pavucontrol
    playerctl

    # Network / bluetooth
    networkmanagerapplet
    blueman

    # System utilities
    brightnessctl
    imagemagick

    # Theming (GTK)
    gnome-themes-extra
    nwg-look

    # Qt Wayland support
    qt5.qtwayland
    qt6.qtwayland

    # MTP / mobile devices
    gvfs
  ];

  # -------------------------------------------------
  # Notes
  # -------------------------------------------------
  #
  # Login flow:
  # - select Hyprland in SDDM
  # - login
  #
  # Required companion modules:
  # - fonts.nix (nerd fonts, font-awesome)
  # - networking/tailscale.nix (optional)
  # - hardware/audio.nix
  #
  # Optional ML4W-style enhancements:
  # - quickshell (experimental shell UI)
  # - uwsm (session manager)
  #
}
