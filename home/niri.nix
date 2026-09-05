# ../../home/niri.nix
{ lib, pkgs, config, osConfig, ... }:

{
  # ===========================================================================
  # Imports
  # ===========================================================================

  imports = [
    ./mime.nix
  ];

  # ===========================================================================
  # Applications
  # ===========================================================================

  home.packages = with pkgs; [
    # GTK
    adw-gtk3                             # Unofficial GTK 3 port of libadwaita

    # KDE
    kdePackages.ark                      # File archiver by KDE
    kdePackages.dolphin                  # File manager by KDE
    kdePackages.ffmpegthumbs             # FFmpeg-based thumbnail creator for video files
    kdePackages.filelight                # Quickly visualize your disk space usage
    kdePackages.gwenview                 # Image viewer by KDE
    kdePackages.kcalc                    # Calculator offering everything a scientific calculator does, and more
    kdePackages.kdeconnect-kde           # Multi-platform app that allows your devices to communicate
    kdePackages.kdegraphics-thumbnailers # Thumbnailers for various graphics file formats
    kdePackages.kompare                  # Graphical File Differences Tool
    kdePackages.kolourpaint              # Easy-to-use paint program
    kdePackages.okular                   # KDE document viewer
    kdePackages.partitionmanager         # Manage the disk devices, partitions and file systems on your computer
    (kdePackages.qt6ct.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        (pkgs.fetchpatch {
          url = "https://aur.archlinux.org/cgit/aur.git/plain/qt6ct-shenanigans.patch?h=qt6ct-kde";
          hash = "sha256-Q8QOMDy84z6FD0OkSLylEwB+/Zs50jcUgR+4J6Lmwmk=";
        })
      ];
    }))

    # Other GUI
    galculator                           # GTK algebraic and RPN calculator
    meld                                 # Visual diff and merge tool
    usbimager                            # Very minimal GUI app that can write compressed disk images to USB drives
  ];


  # ===========================================================================
  # Noctalia
  # ===========================================================================
  programs.noctalia = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      cursor-style = "block";
      shell-integration-features = "no-cursor";
      scrollback-limit = 50000000;
      mouse-hide-while-typing = true;
    };
  };

  # ===========================================================================
  # Niri theming
  # ===========================================================================
  #
  # Noctalia generates the actual themes. This section connects Niri-specific
  # applications and toolkits to the Noctalia theme.
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # ghostty
  # ---------------------------------------------------------------------------

  programs.ghostty.settings = {
    theme = "noctalia";
  };

  # ---------------------------------------------------------------------------
  # kate
  # ---------------------------------------------------------------------------

  home.activation.kateNoctaliaTheme =
    lib.mkIf config.myApps.kate.enable
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/katerc" \
          --group "UiSettings" \
          --key "ColorScheme" \
          "noctalia"
      '');

  # ---------------------------------------------------------------------------
  # remove gtk min/max/close buttons
  # ---------------------------------------------------------------------------

  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
    };
  };

  # ---------------------------------------------------------------------------
  # qt6ct
  # ---------------------------------------------------------------------------

  home.activation.qt6ctNoctaliaTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      qt6ct_conf="$HOME/.config/qt6ct/qt6ct.conf"

      if [ -f "$qt6ct_conf" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed \
          -i \
          -e "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/noctalia.conf|" \
          -e "s|^standard_dialogs=.*|standard_dialogs=xdgdesktopportal|" \
          "$qt6ct_conf"
      fi
    '';

  # ===========================================================================
  # Desktop integration
  # ===========================================================================

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

  # ===========================================================================
  # Niri configuration
  # ===========================================================================

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
