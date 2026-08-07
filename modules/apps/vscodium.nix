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
 #         name = "kdl";
  #        publisher = "kdl-org";
   #       version = "2.1.0";
    #      hash = "sha256-kT7IyhRwuOc+jHDcPiwN768eqgIxFCSndTGk4NS9/QY=";
        }
      ];
    };
  };
}



