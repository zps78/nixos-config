# ../../home/theme.nix

{ config, lib, pkgs, ... }:

{
  options.myDesktop.theme.enable =
    lib.mkEnableOption "Desktop theme";

  config = lib.mkIf config.myDesktop.theme.enable {

    ########################################
    ## Packages
    ########################################

    home.packages = with pkgs; [
      kdePackages.breeze-icons
    ];

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
        package = pkgs.kdePackages.breeze-gtk;
        name = "Breeze-Dark";
      };

      # Silence Home Manager warning
      gtk4.theme = config.gtk.theme;

      iconTheme = {
        package = pkgs.kdePackages.breeze-icons;
        name = "breeze-dark";
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
    };
  };
}
