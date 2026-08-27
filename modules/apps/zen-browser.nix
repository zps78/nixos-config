# ../../modules/apps/zen-browser.nix
{ config, inputs, pkgs, lib, ... }:

let
  cfg = config.myApps.zen-browser;

  prefs = {
    "extensions.autoDisableScopes" = 0;
    "browser.backspace_action" = 0;
    "extensions.pocket.enabled" = false;
    "signon.rememberSignons" = false;
  };

in
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  options.myApps.zen-browser.enable =
    lib.mkEnableOption "Zen Browser";

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;

      profiles.default = {
        settings = prefs;

        extensions.packages =
          let
            firefoxAddons = pkgs.extend inputs.firefox-addons.overlays.default;
          in
          with firefoxAddons.firefox-addons; [
            ublock-origin
            sponsorblock
            keepa
            proton-pass
            print-edit-we
            video-downloadhelper
            consent-o-matic
            torrent-control
          ];

        search = {
          force = true;
          default = "ddg";

          engines = {
            startpage = {
              name = "Startpage";
              urls = [
                {
                  template =
                    "https://www.startpage.com/sp/search?query={searchTerms}";
                }
              ];
              definedAliases = [ "@sp" ];
            };

            nixpkgs = {
              name = "nixpkgs packages";
              urls = [
                {
                  template =
                    "https://search.nixos.org/packages?query={searchTerms}";
                }
              ];
              icon =
                "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
          };
        };

        userChrome = ''
          /* Stylix-compatible Zen UI customization can go here. */
        '';
      };
    };
  };
}
