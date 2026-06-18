# ../../modules/apps/ardour.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.ardour.enable =
    lib.mkEnableOption "Ardour";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.ardour.enable {
    home.packages = with pkgs; [
      ardour
    ];
  };
}
