# ../../modules/apps/lutris.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.lutris.enable =
    lib.mkEnableOption "Lutris";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.lutris.enable {
    home.packages = with pkgs; [
      lutris
    ];
  };
}
