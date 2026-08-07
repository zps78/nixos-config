# ../../modules/apps/vscodium.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.vscodium.enable =
    lib.mkEnableOption "VSCodium";

  config = lib.mkIf config.myApps.vscodium.enable {
    programs.vscodium = {
      enable = true;

    profiles.default.extensions =
      (with pkgs.vscode-extensions; [
        enkia.tokyo-night
        esbenp.prettier-vscode
        jeff-hykin.better-nix-syntax
        ]
      )
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
        name = "kdl";
        publisher = "v1hz";
        version = "2.1.3";
        # Replace after first build failure
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        }
      ];
    };
  };
}



