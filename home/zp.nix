{ config, pkgs, ... }:

{
  imports = [
   # ../modules/.nix
  ];

  home.username = "zp";
  home.homeDirectory = "/home/zp";

  home.stateVersion = "25.11"; # match your NixOS version

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    simple-scan
  ];
}
