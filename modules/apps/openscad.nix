# ../../modules/apps/openscad.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.openscad.enable =
    lib.mkEnableOption "OpenSCAD";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.openscad.enable {
    home.packages = with pkgs; [
      openscad
    ];
  };
}
