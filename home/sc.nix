# ../../home/sc.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/sc.nix
  ];

  home.username = "sc";
  home.homeDirectory = "/home/sc";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "sc";
        email = "mostly@kepler";
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
