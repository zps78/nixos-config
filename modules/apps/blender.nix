# ../../modules/apps/blender.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.blender.enable =
    lib.mkEnableOption "Blender";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.blender.enable {
    home.packages = with pkgs; [
      blender
    ];
  };
}
