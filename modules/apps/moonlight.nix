# ../../modules/apps/moonlight.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.moonlight.enable = lib.mkEnableOption "Moonlight";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.moonlight.enable {
    home.packages = with pkgs; [
      moonlight-qt
    ];
  };
}
