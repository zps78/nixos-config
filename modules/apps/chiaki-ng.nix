# ../../modules/apps/chiaki-ng.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.chiaki-ng.enable =
    lib.mkEnableOption "Chiaki-ng";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.chiaki-ng.enable {
    home.packages = with pkgs; [
      chiaki-ng
    ];
  };
}