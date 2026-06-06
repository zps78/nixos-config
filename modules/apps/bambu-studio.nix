# ../../modules/apps/bambu-studio.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.bambu-studio.enable =
    lib.mkEnableOption "Bambu-studio";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.bambu-studio.enable {
    home.packages = with pkgs; [
      bambu-studio
    ];
  };
}
