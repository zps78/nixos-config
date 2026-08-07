# ../../home/theme.nix
{ config, lib, pkgs, ... }:

{
  options.myDesktop.theme.enable =
    lib.mkEnableOption "Desktop theme";

  config = lib.mkIf config.myDesktop.theme.enable {

    ########################################
    ## Cursor
    ########################################

    home.pointerCursor = {
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
        package = pkgs.kdePackages.breeze-gtk;
        name = "Breeze-Dark";
      };

      iconTheme = {
        package = pkgs.kdePackages.breeze-icons;
        name = "Breeze Dark";
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
        name = "Breeze";
        package = pkgs.kdePackages.breeze;
      };

      platformTheme = {
        name = "gtk3";
      };
    };

    ########################################
    ## XDG
    ########################################

    xdg.mimeApps.enable = true;

    ########################################
    ## Environment
    ########################################

    home.sessionVariables = {

      GTK_THEME = "Breeze-Dark";

      QT_STYLE_OVERRIDE = "Breeze";

      QT_QPA_PLATFORMTHEME = "gtk3";

      XDG_CURRENT_DESKTOP = "niri";
    };
  };
}