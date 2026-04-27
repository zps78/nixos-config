# ../../modules/apps/plex.nix
{ config, pkgs, ... }:

{
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
    plex-desktop
    qt6.qtwayland
    qt6.qtwebengine
  ];
}
