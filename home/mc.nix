{ config, pkgs, lib, ... }:

{
  imports = [
   # ../modules/.nix
  ];

  home.username = "mc";
  home.homeDirectory = "/home/mc";

  home.file.".wallpaper.jpg".source = ../wallpapers/wallpaper-mc.jpg;
  home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
  ${pkgs.qt6.qttools}/bin/qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var Desktops = desktops();
    for (i=0;i<Desktops.length;i++) {
      d = Desktops[i];
      d.wallpaperPlugin = "org.kde.image";
      d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
      d.writeConfig("Image", "file://${config.home.homeDirectory}/.wallpaper.jpg");
    }
  '
'';
  home.stateVersion = "25.11"; # match your NixOS version

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    simple-scan
  ];
}
