# ../../home/users/zp.nix
{ pkgs, lib, osConfig, ... }:

{
  ############################################################
  # Home Manager basics
  ############################################################

  home.username                                  = "zp";
  home.homeDirectory                             = "/home/zp";
  home.stateVersion                              = "25.11";          # match your NixOS version

  ############################################################
  # Imports (user environment composition)
  ############################################################

  imports = [
    ../../modules/apps
    ../theme.nix
  ]
  ++ lib.optionals (osConfig.myDesktop.stack == "niri") [
    ../niri.nix
  ];
  myDesktop.force.theme.enable                   = true;             # force breeze dark theme

  ############################################################
  # User applications
  ############################################################

  myApps = {

    # 3d modeling
    bambu-studio.enable                          = false;            # PC Software for BambuLab's 3D printers
    blender.enable                               = false;            # 3D Creation/Animation/Publishing System
    freecad.enable                               = true;             # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    openscad.enable                              = false;            # 3D parametric model compiler
    orca-slicer.enable                           = false;            # G-code generator for 3D printers

    # programming
    godot.enable                                 = false;            # Free and Open Source 2D and 3D game engine
    kate.enable                                  = true;             # Advanced text editor
    vscodium.enable                              = false;            # VS Code without MS branding/telemetry/licensing

    # office and productivity
    office.enable                                = true;             # Office suite that combines text, spreadsheet and presentation editors
    proton-pass.enable                           = true;             # Desktop application for Proton Pass
    telegram.enable                              = true;             # Telegram Desktop messaging app
    thunderbird.enable                           = false;            # Full-featured e-mail client

    # Emulation / virtualization
    bottles.enable                               = true;             # Easy-to-use wineprefix manager
  # libvirt                                      > enable service in the host's configuration.nix
  # wine                                         > enable feature in the host's configuration.nix

    # gaming
    chiaki-ng.enable                             = true;             # Next-Generation of Chiaki (the open-source remote play client for PlayStation)
    lutris.enable                                = false;            # Open Source gaming platform for GNU/Linux
    moonlight.enable                             = true;             # Play your PC games on almost any device
  # steam                                        > enable feature in the host's configuration.nix

    # media editing
    ardour.enable                                = false;            # Multi-track hard disk recording software
    audacity.enable                              = true;             # Sound editor with graphical UI
    handbrake.enable                             = true;             # Tool for converting video files and ripping DVDs
    losslesscut.enable                           = true;             # Swiss army knife of lossless video/audio editing
    mkvtoolnix.enable                            = true;             # Cross-platform tools for Matroska
    obs-studio.enable                            = false;            # Free and open source software for video recording and live streaming

    # media players
    iptvnator.enable                             = true;             # Cross-platform IPTV player application with support for m3u/m3u8 playlists, favorites, TV guide, and TV archive/catchup
    freetube.enable                              = true;             # Open Source YouTube app for privacy
    plex.enable                                  = true;             # Media library streaming server
    spotify.enable                               = true;             # Play music from the Spotify music service
    vlc.enable                                   = true;             # Cross-platform media player and streaming server

    # image editors
    gimp.enable                                  = true;             # GNU Image Manipulation Program
    darktable.enable                             = true;             # Virtual lighttable and darkroom for photographers
    krita.enable                                 = false;            # Free and open source painting application

    # web browsers
    firefox.enable                               = true;             # Web browser built from Firefox source tree
    zen-browser.enable                           = true;             # Privacy-focused internet browser
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "zp";
        email = "mostly@kuro";
      };
      init.defaultBranch = "main";
    };
  };

  home.packages = with pkgs; [

 ## Remote access
    remmina
  # sunshine        # -> import sunshine.nix in the host's configuration.nix
  # teamviewer

 ## Virtualization / Emulation
  # waydroid        # -> import waydroid.nix in the host's configuration.nix
  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
