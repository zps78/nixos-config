# ../../home/steam.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/bb.nix
  ];

  home.username = "bb";
  home.homeDirectory = "/home/bb";

  # ----------------------
  # Packages needed for activation scripts
  # ----------------------
  home.packages = with pkgs; [

  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
