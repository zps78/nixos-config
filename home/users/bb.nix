# ../../home/users/bb.nix
{ pkgs, lib, osConfig, ... }:

{
  ############################################################
  # Home Manager basics
  ############################################################

  home.username                                  = "bb";
  home.homeDirectory                             = "/home/bb";
  home.stateVersion                              = "25.11";          # match your NixOS version

  ############################################################
  # Imports (user environment composition)
  ############################################################

  imports = [
    ../../modules/apps-user
    ../common.nix
  ]
  ++ lib.optionals (osConfig.myDesktop.stack == "niri") [
    ../niri.nix
  ];

  ############################################################
  # User applications
  ############################################################

  myApps = {

    # 3d modeling
    bambu-studio.enable                          = false;            # PC Software for BambuLab's 3D printers
    blender.enable                               = false;            # 3D Creation/Animation/Publishing System
    f3d.enable                                   = true;             # Fast minimalist 3D viewer (VTK)
    freecad.enable                               = false;            # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    openscad.enable                              = false;            # 3D parametric model compiler
    orca-slicer.enable                           = false;            # G-code generator for 3D printers

    # programming
    godot.enable                                 = false;            # Free and Open Source 2D and 3D game engine
    claude-code.enable                           = false;            # Claude Code CLI
    vscodium.enable                              = false;            # VS Code without MS branding/telemetry/licensing
    zed.enable                                   = true;             # High-performance, multiplayer code editor from the creators of Atom and Tree-sitter

    # office and productivity
    office.enable                                = false;            # Office suite that combines text, spreadsheet and presentation editors
    xournalpp.enable                             = false;            # Xournal++ is a handwriting Notetaking software with PDF annotation support
    pdfarranger.enable                           = false;            # Merge or split pdf documents and rotate, crop and rearrange their pages using a graphical interface
    proton-pass.enable                           = false;            # Desktop application for Proton Pass
    telegram.enable                              = false;            # Telegram Desktop messaging app
    thunderbird.enable                           = false;            # Full-featured e-mail client
    winapps.enable                               = false;            # Seamless Windows apps (RDP into karma's Office VM)

    # KDE apps
    kde.enable                                   = true;             # Ark, Okular, Gwenview (+ qt6ct theming) - not dolphin, see modules/apps-user/kde.nix

    # Emulation / virtualization
    bottles.enable                               = true;             # Easy-to-use wineprefix manager
  # libvirt                                      > enable service in the host's configuration.nix
  # wine                                         > enable feature in the host's configuration.nix

    # gaming
    chiaki-ng.enable                             = false;            # Next-Generation of Chiaki (the open-source remote play client for PlayStation)
    lutris.enable                                = true;             # Open Source gaming platform for GNU/Linux
    moonlight.enable                             = false;            # Play your PC games on almost any device - bb is the stream host, not a client
  # steam                                        > enable feature in the host's configuration.nix

    # media editing
    ardour.enable                                = false;            # Multi-track hard disk recording software
    audacity.enable                              = false;            # Sound editor with graphical UI
    easyeffects.enable                           = false;            # System-wide audio effects (EQ, compressor, limiter)
    handbrake.enable                             = false;            # Tool for converting video files and ripping DVDs
    losslesscut.enable                           = false;            # Swiss army knife of lossless video/audio editing
    mkvtoolnix.enable                            = false;            # Cross-platform tools for Matroska
    obs-studio.enable                            = true;             # Free and open source software for video recording and live streaming

    # media players
    cava.enable                                  = false;            # Console audio visualizer (ALSA/PipeWire)
    iptvnator.enable                             = false;            # Cross-platform IPTV player application with support for m3u/m3u8 playlists, favorites, TV guide, and TV archive/catchup
    freetube.enable                              = false;            # Open Source YouTube app for privacy
    mpv.enable                                   = false;            # General-purpose media player, fork of MPlayer and mplayer2 ( + uosc + thumbfast )
    plex-tui.enable                              = false;            # Terminal Plex client for browsing and watching media
    plex.enable                                  = false;            # Media library streaming server
    spotatui.enable                              = false;            # Fully standalone Spotify client for the terminal
    spotify.enable                               = false;            # Play music from the Spotify music service
    vlc.enable                                   = false;            # Cross-platform media player and streaming server

    # image editors
    gimp.enable                                  = false;            # GNU Image Manipulation Program
    darktable.enable                             = false;            # Virtual lighttable and darkroom for photographers
    krita.enable                                 = false;            # Free and open source painting application

    # web browsers
    brave.enable                                 = false;            # Privacy-oriented browser for Desktop and Laptop computers
    firefox.enable                               = false;            # Web browser built from Firefox source tree
    zen-browser.enable                           = true;             # Privacy-focused internet browser
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "bb";
        email = "mostly@krieger";
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

  ############################################################
  # Fleet SSH access (krieger only - bb.nix is only used there)
  ############################################################
  #
  # krieger-fleet-key is a dedicated keypair (not any personal key) for
  # reaching the rest of the fleet - see secrets/secrets.nix. Its
  # private half is agenix-encrypted, decrypted only on krieger at
  # activation via age.secrets.krieger-fleet-key in
  # hosts/krieger/configuration.nix. Public halves are plain-text,
  # committed, and added to each target's authorized_keys.
  #
  programs.ssh = {
    enable = true;

    # home-manager's enableDefaultConfig (on by default) is slated for
    # removal - this is its own documented migration snippet, copied
    # verbatim, so switching it off is a pure no-op rather than a
    # behavior change.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      kepler = {
        User = "sc";
        IdentityFile = "/run/agenix/krieger-fleet-key";
        IdentitiesOnly = true;
      };
      kimi = {
        User = "gt";
        IdentityFile = "/run/agenix/krieger-fleet-key";
        IdentitiesOnly = true;
      };
      krugerrand = {
        User = "zp";
        IdentityFile = "/run/agenix/krieger-fleet-key";
        IdentitiesOnly = true;
      };
      kuro = {
        User = "zp";
        IdentityFile = "/run/agenix/krieger-fleet-key";
        IdentitiesOnly = true;
      };
      # karma isn't part of this flake (Unraid) - its authorized_keys
      # is managed by hand over SSH, not by nix.
      karma = {
        User = "root";
        IdentityFile = "/run/agenix/krieger-fleet-key";
        IdentitiesOnly = true;
      };
    };
  };

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
