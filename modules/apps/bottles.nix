# ../../modules/apps/bottles.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.bottles.enable =
    lib.mkEnableOption "Bottles";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.bottles.enable {
    home.packages = with pkgs; [
      bottles
    ];
  };
}
