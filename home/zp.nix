# ../../home/zp.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/zp.nix
  ];

  home.username = "zp";
  home.homeDirectory = "/home/zp";

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
