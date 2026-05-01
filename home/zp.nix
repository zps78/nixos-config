# ../../home/zp.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/zp.nix
  ];

  home.username = "zp";
  home.homeDirectory = "/home/zp";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "zp";
        email = "mostly@krugerrand";
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
