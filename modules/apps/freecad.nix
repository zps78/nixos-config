# ../../modules/apps/freecad.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.freecad.enable =
    lib.mkEnableOption "FreeCAD";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.freecad.enable {
    home.packages = with pkgs; [
      freecad
    ];
  };
}
