# ../../modules/apps-user/zed.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.zed.enable =
    lib.mkEnableOption "Zed";

  config = lib.mkIf config.myApps.zed.enable {

    programs.zed-editor = {
      enable = true;

      # ----------------------
      # Language servers/tools
      # ----------------------
      extraPackages = with pkgs; [
        nixd
        tombi
      ];

      # ----------------------
      # Extensions
      # ----------------------
      extensions = [
        "nix"
        "toml"
      ];

      # ----------------------
      # Settings
      # ----------------------
      userSettings = {
        tab_size = 2;
        hard_tabs = false;

        format_on_save = "on";

        # Follow Noctalia's theme. Noctalia's "zed" template regenerates
        # ~/.config/zed/themes/noctalia.json on every wallpaper/theme
        # change; "mode = system" tracks its light/dark switch via the
        # xdg-desktop-portal color-scheme. Swap to the "* Transparent"
        # variants for a translucent editor.
        theme = {
          mode = "system";
          light = "Noctalia Light";
          dark = "Noctalia Dark";
        };

        git_panel = {
          tree_view = true;
        };

        tabs = {
          git_status = true;
        };

        languages = {
          Nix = {
            language_servers = [ "nixd" ];
          };
          TOML = {
            language_servers = [ "tombi" ];
          };
        };
      };
    };
  };
}
