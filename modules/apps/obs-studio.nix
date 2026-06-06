# ../../modules/apps/obs-studio.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.obs-studio.enable =
    lib.mkEnableOption "OBS Studio";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.obs-studio.enable {
    home.packages = with pkgs; [
      obs-studio
    ];
  };
}
