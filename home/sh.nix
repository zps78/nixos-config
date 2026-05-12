# ../../home/sh.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/sh.nix
  ];

  home.username = "sh";
  home.homeDirectory = "/home/sh";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "sh";
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
