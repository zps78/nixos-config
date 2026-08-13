# ../../home/theme.nix
{ config, lib, pkgs, ... }:

{
  options.myDesktop.force.theme.enable =
    lib.mkEnableOption "Force desktop theme";

  config = lib.mkIf config.myDesktop.force.theme.enable {

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
        name = "kde";
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
        GTK_THEME = "gruvbox-dark";
        QT_STYLE_OVERRIDE = "Breeze";
    };
  };
}
