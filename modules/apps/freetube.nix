# ../../modules/apps/freetube.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.freetube.enable =
    lib.mkEnableOption "FreeTube";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.freetube.enable {
    home.packages = with pkgs; [
      freetube
    ];
  };
}
