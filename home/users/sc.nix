# ../../home/sc.nix
{ config, pkgs, lib, osConfig, inputs, ... }:

{
  ############################################################
  # Home Manager basics
  ############################################################

  home.username                                  = "sc";
  home.homeDirectory                             = "/home/sc";
  home.stateVersion                              = "25.11";          # match your NixOS version

  ############################################################
  # Imports (user environment composition)
  ############################################################

  imports = [
    ../../modules/apps
  ]
  ++ lib.optionals (osConfig.myDesktop.stack == "niri") [
    ./niri.nix
  ];

  ############################################################
  # User applications (only truly global desktop apps)
  ############################################################

  myApps = {

    # 3d modeling
    bambu-studio.enable                          = false;            # PC Software for BambuLab's 3D printers
    blender.enable                               = true;             # 3D Creation/Animation/Publishing System
    freecad.enable                               = true;             # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    openscad.enable                              = false;            # 3D parametric model compiler
    orca-slicer.enable                           = true;             # G-code generator for 3D printers

    # programming
    godot.enable                                 = true;             # Free and Open Source 2D and 3D game engine
    vscodium.enable                              = true;             # VS Code without MS branding/telemetry/licensing

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
    lutris.enable                                = true;             # Open Source gaming platform for GNU/Linux
    moonlight.enable                             = true;             # Play your PC games on almost any device
  # steam                                        > enable feature in the host's configuration.nix

    # media editing
    ardour.enable                                = true;             # Multi-track hard disk recording software
    audacity.enable                              = true;             # Sound editor with graphical UI
    handbrake.enable                             = false;            # Tool for converting video files and ripping DVDs
    losslesscut.enable                           = true;             # Swiss army knife of lossless video/audio editing
    mkvtoolnix.enable                            = false;            # Cross-platform tools for Matroska
    obs-studio.enable                            = true;             # Free and open source software for video recording and live streaming

    # media players
    freetube.enable                              = true;             # Open Source YouTube app for privacy
    plex.enable                                  = true;             # Media library streaming server
    spotify.enable                               = true;             # Play music from the Spotify music service
    vlc.enable                                   = true;             # Cross-platform media player and streaming server

    # image editors
    gimp.enable                                  = true;             # GNU Image Manipulation Program
    darktable.enable                             = false;            # Virtual lighttable and darkroom for photographers
    krita.enable                                 = true;             # Free and open source painting application

    # web browsers
    firefox.enable                               = true;             # Web browser built from Firefox source tree
    zen-browser.enable                           = true;             # Privacy-focused internet browser
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "sc";
        email = "mostly@kepler";
      };
      init.defaultBranch = "main";
    };
  };

  home.packages = with pkgs; [

 ## Remote access
  # remmina
  # sunshine        # -> import sunshine.nix in the host's configuration.nix
  # teamviewer

 ## Virtualization / Emulation
  # waydroid        # -> import waydroid.nix in the host's configuration.nix
  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
