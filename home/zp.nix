{ config, pkgs, ... }:

{
  imports = [
   # ../modules/.nix
  ];

  home.file.".wallpaper.jpg".source = ../wallpapers/wallpaper-zp.jpg;
  home.username = "zp";
  home.homeDirectory = "/home/zp";
home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
  ${pkgs.kdePackages.plasma-workspace}/bin/qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
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
