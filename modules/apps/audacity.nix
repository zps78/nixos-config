# ../../modules/apps/audacity.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.audacity.enable =
    lib.mkEnableOption "Audacity";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.audacity.enable {
    home.packages = with pkgs; [
      audacity
    ];
  };
}
