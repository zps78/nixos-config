{ config, pkgs, ... }:

{
  imports = [
   # ../modules/.nix
  ];

  home.file.".wallpaper.jpg".source = ../wallpapers/wallpaper-mc.jpg;
  home.username = "mc";
  home.homeDirectory = "/home/mc";

  home.stateVersion = "25.11"; # match your NixOS version

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    simple-scan
  ];
}
