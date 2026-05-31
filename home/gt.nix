# ../../home/gt.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
#   ./niri.nix
    ../modules/apps/gt.nix
  ];

  home.username = "gt";
  home.homeDirectory = "/home/gt";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "gt";
        email = "mostly@kimi";
      };

      init.defaultBranch = "main";
    };
  };

  # ----------------------
  # Packages needed for activation scripts
  # ----------------------
  home.packages = with pkgs; [

  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
