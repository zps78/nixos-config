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
    freecad.enable                               = true;             # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    openscad.enable                              = false;            # 3D parametric model compiler
    orca-slicer.enable                           = true;             # G-code generator for 3D printers

    # programming
    godot.enable                                 = false;            # Free and Open Source 2D and 3D game engine
    claude-code.enable                           = true;             # Claude Code CLI
    vscodium.enable                              = false;            # VS Code without MS branding/telemetry/licensing
    zed.enable                                   = true;             # High-performance, multiplayer code editor from the creators of Atom and Tree-sitter

    # office and productivity
    office.enable                                = true;             # Office suite that combines text, spreadsheet and presentation editors
    xournalpp.enable                             = true;             # Xournal++ is a handwriting Notetaking software with PDF annotation support
    pdfarranger.enable                           = true;             # Merge or split pdf documents and rotate, crop and rearrange their pages using a graphical interface
    proton-pass.enable                           = true;             # Desktop application for Proton Pass
    telegram.enable                              = true;             # Telegram Desktop messaging app
    thunderbird.enable                           = false;            # Full-featured e-mail client
    winapps.enable                               = true;             # Seamless Windows apps (RDP into karma's Office VM)

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
    easyeffects.enable                           = true;             # System-wide audio effects (EQ, compressor, limiter)
    handbrake.enable                             = true;             # Tool for converting video files and ripping DVDs
    losslesscut.enable                           = true;             # Swiss army knife of lossless video/audio editing
    mkvtoolnix.enable                            = true;             # Cross-platform tools for Matroska
    obs-studio.enable                            = false;            # Free and open source software for video recording and live streaming

    # media players
    cava.enable                                  = true;             # Console audio visualizer (ALSA/PipeWire)
    iptvnator.enable                             = true;             # Cross-platform IPTV player application with support for m3u/m3u8 playlists, favorites, TV guide, and TV archive/catchup
    freetube.enable                              = true;             # Open Source YouTube app for privacy
    mpv.enable                                   = true;             # General-purpose media player, fork of MPlayer and mplayer2 ( + uosc + thumbfast )
    plex-tui.enable                              = true;             # Terminal Plex client for browsing and watching media
    plex.enable                                  = true;             # Media library streaming server
    spotatui.enable                              = true;             # Fully standalone Spotify client for the terminal
    spotify.enable                               = true;             # Play music from the Spotify music service
    vlc.enable                                   = false;            # Cross-platform media player and streaming server

    # image editors
    gimp.enable                                  = true;             # GNU Image Manipulation Program
    darktable.enable                             = true;             # Virtual lighttable and darkroom for photographers
    krita.enable                                 = true;             # Free and open source painting application

    # web browsers
    brave.enable                                 = true;             # Privacy-oriented browser for Desktop and Laptop computers
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

  ############################################################
  # Fleet SSH access (kuro + krugerrand - the two admin machines;
  # zp.nix is also used by kepler/kimi as a leaf-only target, which
  # don't get this)
  ############################################################
  #
  # kuro-fleet-key / krugerrand-fleet-key are dedicated keypairs (not
  # the personal GitHub/karma key), one per admin machine, for reaching
  # the rest of the fleet - see secrets/secrets.nix. Each private half
  # is agenix-encrypted, decrypted only on its own host at activation
  # via age.secrets.<host>-fleet-key in that host's configuration.nix.
  # Public halves are plain-text, committed, and added to each target's
  # authorized_keys. krieger used to be the second admin machine
  # (krieger-fleet-key) but was demoted to a leaf once it got
  # autologin enabled - a lower-trust boot state we didn't want holding
  # fleet-wide SSH reach - and krugerrand took its place instead.
  #
  programs.ssh = lib.mkIf
    (builtins.elem osConfig.networking.hostName [ "kuro" "krugerrand" ])
    (let
      identityFile =
        "/run/agenix/${osConfig.networking.hostName}-fleet-key";
    in {
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
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
        kimi = {
          User = "gt";
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
        krieger = {
          User = "bb";
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
        # karma isn't part of this flake (Unraid) - its authorized_keys
        # is managed by hand over SSH, not by nix.
        karma = {
          User = "root";
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
      }
      # Each admin machine also reaches the other one, not itself.
      // lib.optionalAttrs (osConfig.networking.hostName == "kuro") {
        krugerrand = {
          User = "zp";
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
      }
      // lib.optionalAttrs (osConfig.networking.hostName == "krugerrand") {
        kuro = {
          User = "zp";
          IdentityFile = identityFile;
          IdentitiesOnly = true;
        };
      };
    });

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
