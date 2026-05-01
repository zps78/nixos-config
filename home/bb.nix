# ../../home/bb.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/bb.nix
  ];

  home.username = "bb";
  home.homeDirectory = "/home/bb";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "bb";
        email = "mostly@krieger";
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
