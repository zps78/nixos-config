# ../../modules/apps/zed.nix
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
      userSettings =
        {
          tab_size = 2;
          hard_tabs = false;

          format_on_save = "on";

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
