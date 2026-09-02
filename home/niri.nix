# ../../home/niri.nix
{ pkgs, osConfig, ... }:

{
  imports = [
    ./mime.nix
  ];

  programs.alacritty.enable = true;
  programs.noctalia = {
    enable = true;
  };

  home.packages = with pkgs; [
    grim                                 # Grab images from a Wayland compositor

    playerctl                            # Command-line utility and library for controlling media players that implement MPRIS

    slurp                                # Select a region in a Wayland compositor

    adw-gtk3                             # Unofficial GTK 3 port of libadwaita

    kdePackages.qt6ct                    # Qt6 Configuration Tool

    kdePackages.ark                      # File archiver by KDE

    kdePackages.dolphin                  # File manager by KDE

    kdePackages.ffmpegthumbs             # FFmpeg-based thumbnail creator for video files

    kdePackages.filelight                # Quickly visualize your disk space usage

    kdePackages.gwenview                 # Image viewer by KDE

    usbimager                            # Very minimal GUI app that can write compressed disk images to USB drives

    galculator                           # GTK algebraic and RPN calculator

    kdePackages.kdeconnect-kde           # Multi-platform app that allows your devices to communicate

    kdePackages.kdegraphics-thumbnailers # Thumbnailers for various graphics file formats

    kdePackages.kompare                  # Graphical File Differences Tool
    meld                                 # Visual diff and merge tool

    kdePackages.okular                   # KDE document viewer

    kdePackages.partitionmanager         # Manage the disk devices, partitions and file systems on your computer
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
    "niri/cursor.kdl".source             = ../dotfiles/niri/cursor.kdl;
    "niri/decorations.kdl".source        = ../dotfiles/niri/decorations.kdl;
    "niri/input.kdl".source              = ../dotfiles/niri/input.kdl;
    "niri/layout.kdl".source             = ../dotfiles/niri/layout.kdl;
    "niri/screenshots.kdl".source        = ../dotfiles/niri/screenshots.kdl;
    "niri/spawn-at-startup.kdl".source   = ../dotfiles/niri/spawn-at-startup.kdl;
    "niri/window-rules.kdl".source       = ../dotfiles/niri/window-rules.kdl;
    "niri/output.kdl".source             = ../hosts/${osConfig.networking.hostName}/niri/output.kdl;

    "noctalia/templates.toml".source     = ../dotfiles/noctalia/templates.toml;
    };
}
