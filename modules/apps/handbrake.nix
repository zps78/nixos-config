# ../../modules/apps/handbrake.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.handbrake.enable =
    lib.mkEnableOption "Handbrake";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.handbrake.enable {
    home.packages = with pkgs; [
      handbrake
    ];
  };
}
