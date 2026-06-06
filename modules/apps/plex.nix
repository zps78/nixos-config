# ../../modules/apps/plex.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.plex.enable = 
    lib.mkEnableOption "Plex";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.plex.enable {
    home.packages = with pkgs; [
      plex-desktop
      qt6.qtwayland
      qt6.qtwebengine
    ];
  };
}
