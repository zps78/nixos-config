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

  home.packages = with pkgs; [
    brightnessctl            # This program allows you read and control device brightness
    grim                     # Grab images from a Wayland compositor
    noctalia-shell           # Sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell
    playerctl                # Command-line utility and library for controlling media players that implement MPRIS
    slurp                    # Select a region in a Wayland compositor
    wl-clipboard             # Command-line copy/paste utilities for Wayland

#   swaylock                 # Screen locker for Wayland
    kdePackages.ark                      # File archiver by KDE
    kdePackages.dolphin                  # File manager by KDE
    kdePackages.ffmpegthumbs             # FFmpeg-based thumbnail creator for video files
    kdePackages.filelight                # Quickly visualize your disk space usage
    kdePackages.gwenview                 # Image viewer by KDE
    kdePackages.isoimagewriter           # Program to write hybrid ISO files onto USB disks
    kdePackages.kate                     # Advanced text editor
    kdePackages.kcalc                    # Calculator offering everything a scientific calculator does, and more
    kdePackages.kdeconnect-kde           # Multi-platform app that allows your devices to communicate
    kdePackages.kdegraphics-thumbnailers # Thumbnailers for various graphics file formats
    kdePackages.kompare                  # Graphical File Differences Tool
    kdePackages.konsole                  # Terminal emulator by KDE
    kdePackages.okular                   # KDE document viewer
    kdePackages.partitionmanager         # Manage the disk devices, partitions and file systems on your computer
    ];

#  xdg.configFile."niri".source = ../dotfiles/niri;
  xdg.configFile."niri".source =
  config.lib.file.mkOutOfStoreSymlink
    "/home/zp/nixos-config/dotfiles/niri";
}