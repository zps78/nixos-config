# ../../home/niri.nix
{ config, pkgs, ... }:

{
  programs.alacritty.enable = true;
  programs.swaylock.enable = true;
  services.mako.enable = true;

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "niri msg action power-off-monitors"; }
    ];
  };

  programs.noctalia-shell = {
    enable = true;
    settings = { };
  };

  home.packages = with pkgs; [
    brightnessctl            # This program allows you read and control device brightness
    grim                     # Grab images from a Wayland compositor
    playerctl                # Command-line utility and library for controlling media players that implement MPRIS
    slurp                    # Select a region in a Wayland compositor
#   swaybg                   # Wallpaper tool for Wayland compositors
    wl-clipboard             # Command-line copy/paste utilities for Wayland
#   pavucontrol              # PulseAudio Volume Control
#   blueman                  # GTK-based Bluetooth Manager

#   alacritty                # Cross-platform, GPU-accelerated terminal emulator (Super+T default)
#   mako                     # Lightweight Wayland notification daemon
#   noctalia-shell           # Sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell
#   swayidle                 # Idle management daemon for Wayland
#   swaylock                 # Screen locker for Wayland
#   xwayland-satellite       # Xwayland outside your Wayland compositor
  ];

  xdg.configFile."niri/config.kdl".source =
    ../dotfiles/niri/config.kdl;
}