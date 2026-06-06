# ../../modules/apps/vscodium.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.vscodium.enable =
    lib.mkEnableOption "VSCodium";

  config = lib.mkIf config.myApps.vscodium.enable {
    programs.vscodium = {
      enable = true;

      profiles.default.extensions = with pkgs.vscode-extensions; [
        enkia.tokyo-night
        esbenp.prettier-vscode
        jeff-hykin.better-nix-syntax
      ];
    };
  };
}
