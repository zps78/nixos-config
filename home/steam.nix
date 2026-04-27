# ../../home/steam.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/steam.nix
  ];

  home.username = "steam";
  home.homeDirectory = "/home/steam";

  # ----------------------
  # Packages needed for activation scripts
  # ----------------------
  home.packages = with pkgs; [
#    qt6.qttools   # Provides qdbus for KDE activation scripts
  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
