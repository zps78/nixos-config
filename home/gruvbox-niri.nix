# ../../home/gruvbox-niri.nix
{ config, pkgs, lib, ... }:

{
  ########################################
  #####    ALWAYS ON NIRI THEMING    #####
  ########################################

  ########################################
  ## Cursor
  ########################################

  home.pointerCursor = {
    enable = true;

    gtk.enable = true;
    x11.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  ########################################
  ## GTK
  ########################################

  gtk = {
    enable = true;

    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark";
    };

    # Silence Home Manager warning
    gtk4.theme = config.gtk.theme;

    iconTheme = {
      package = pkgs.gruvbox-dark-icons-gtk;
      name = "oomox-gruvbox-dark";
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  ########################################
  ## Qt
  ########################################

  qt = {
    enable = true;

    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };

    kvantum = {
      enable = true;

      themes = [
        pkgs.gruvbox-kvantum
      ];

      settings = {
        General = {
          theme = "Gruvbox-Dark-Brown";
        };
      };
    };
  };

  ########################################
  ## KDE Color Scheme
  ########################################

  xdg.dataFile."color-schemes/Gruvbox.colors".source =
    ./gruvbox.colors;

  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=Gruvbox
  '';

  ########################################
  ## XDG
  ########################################

  xdg.mimeApps.enable = true;

  ########################################
  #####     PER APP NIRI THEMING     #####
  ########################################

  ########################################
  ## Alacritty
  ########################################

  xdg.configFile."alacritty/theme.toml".source =
    ../dotfiles/alacritty/gruvbox.toml;

  ########################################
  ## Dolphin
  ########################################

  home.activation.dolphinGruvbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.config/dolphinrc" ]; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
        '/^\[UiSettings\]/,/^\[/ s/^ColorScheme=.*/ColorScheme=Gruvbox/' \
        "$HOME/.config/dolphinrc"
    fi
  '';

  ########################################
  ## Kate
  ########################################

  home.activation.kateGruvbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.config/katerc" ]; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
        '/^\[KTextEditor Renderer\]/,/^\[/ s/^Color Theme=.*/Color Theme=Gruvbox/' \
        "$HOME/.config/katerc"
    fi
  '';

  ########################################
  ## Okular
  ########################################

  home.activation.okularGruvbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.config/okularrc" ]; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
        '/^\[UiSettings\]/,/^\[/ s/^ColorScheme=.*/ColorScheme=Gruvbox/' \
        "$HOME/.config/okularrc"
    fi
  '';

  ########################################
  ## Zed
  ########################################

  programs.zed-editor.userSettings.theme =
    lib.mkIf config.myApps.zed.enable {
      mode = "dark";
      dark = "Gruvbox Dark";
      light = "Gruvbox Light";
    };
}
