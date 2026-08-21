# ../../home/niri.nix
{ pkgs, osConfig, ... }:

{

  imports = [
    ./niri-mime.nix
  ];

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
    brightnessctl                         # This program allows you read and control device brightness
    grim                                  # Grab images from a Wayland compositor
    noctalia-shell                        # Sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell
    playerctl                             # Command-line utility and library for controlling media players that implement MPRIS
    slurp                                 # Select a region in a Wayland compositor
    wl-clipboard                          # Command-line copy/paste utilities for Wayland

#    kdePackages.ark                      # File archiver by KDE
    file-roller
    xfce.thunar-archive-plugin

#    kdePackages.dolphin                  # File manager by KDE
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-media-tags-plugin

#    kdePackages.ffmpegthumbs             # FFmpeg-based thumbnail creator for video files
    ffmpegthumbnailer

#    kdePackages.filelight                # Quickly visualize your disk space usage
    baobab

#    kdePackages.gwenview                 # Image viewer by KDE
    imv

#    kdePackages.isoimagewriter           # Program to write hybrid ISO files onto USB disks
    usbimager

#    kdePackages.kcalc                    # Calculator offering everything a scientific calculator does, and more
    galculator

    kdePackages.kdeconnect-kde           # Multi-platform app that allows your devices to communicate


#    kdePackages.kdegraphics-thumbnailers # Thumbnailers for various graphics file formats
    xfce.tumbler


#    kdePackages.kompare                  # Graphical File Differences Tool
    meld

#    kdePackages.okular                   # KDE document viewer
    evince

#    kdePackages.partitionmanager         # Manage the disk devices, partitions and file systems on your computer
    gparted
    ];

  xdg.dataFile."applications/systemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  xdg.dataFile."applications/kdesystemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  xdg.configFile = {
    "niri/animations.kdl".source         = ../dotfiles/niri/animations.kdl;
    "niri/binds.kdl".source              = ../dotfiles/niri/binds.kdl;
    "niri/config.kdl".source             = ../dotfiles/niri/config.kdl;
    "niri/decorations.kdl".source        = ../dotfiles/niri/decorations.kdl;
    "niri/input.kdl".source              = ../dotfiles/niri/input.kdl;
    "niri/layout.kdl".source             = ../dotfiles/niri/layout.kdl;
    "niri/screenshots.kdl".source        = ../dotfiles/niri/screenshots.kdl;
    "niri/spawn-at-startup.kdl".source   = ../dotfiles/niri/spawn-at-startup.kdl;
    "niri/window-rules.kdl".source       = ../dotfiles/niri/window-rules.kdl;
    "niri/output.kdl".source             = ../hosts/${osConfig.networking.hostName}/niri/output.kdl;

    "alacritty/alacritty.toml".source    = ../dotfiles/alacritty/alacritty.toml;
    "alacritty/breeze.toml".source       = ../dotfiles/alacritty/breeze.toml;
  };
}
