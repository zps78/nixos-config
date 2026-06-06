# ../../modules/apps/gimp.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.gimp.enable =
    lib.mkEnableOption "Gimp - GNU Image Manipulation Program";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.gimp.enable {
    home.packages = with pkgs; [
      gimp
    ];
  };
}
