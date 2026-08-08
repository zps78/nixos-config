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
    ffmpeg-headless
    ffmpegthumbnailer
    grim                     # Grab images from a Wayland compositor
    noctalia-shell           # Sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell
    playerctl                # Command-line utility and library for controlling media players that implement MPRIS
    slurp                    # Select a region in a Wayland compositor
    wl-clipboard             # Command-line copy/paste utilities for Wayland

#   swaylock                 # Screen locker for Wayland
    kdePackages.dolphin          # File manager by KDE
    kdePackages.kdegraphics-thumbnailers
    kdePackages.isoimagewriter   # Program to write hybrid ISO files onto USB disks
    kdePackages.kate             # Advanced text editor
    kdePackages.kcalc            # Calculator offering everything a scientific calculator does, and more
    kdePackages.kdeconnect-kde   # Multi-platform app that allows your devices to communicate
    kdePackages.kompare          # Graphical File Differences Tool
    kdePackages.okular           # KDE document viewer
    kdePackages.partitionmanager # Manage the disk devices, partitions and file systems on your computer
  ];

#  xdg.configFile."niri".source = ../dotfiles/niri;
  xdg.configFile."niri".source =
  config.lib.file.mkOutOfStoreSymlink
    "/home/zp/nixos-config/dotfiles/niri";
}