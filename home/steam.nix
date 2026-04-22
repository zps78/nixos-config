# ../../home/steam.nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11"; # match your NixOS version

  imports = [
    ../modules/apps/steam.nix
  ];

  home.username = "steam";
  home.homeDirectory = "/home/steam";

  # ----------------------
  # Wallpaper files
  # ----------------------
  home.file.".wallpaper.jpg".source = ../wallpapers/wallpaper-steam.jpg;
  home.file.".wallpaper-lock.jpg".source = ../wallpapers/wallpaper-lock-steam.jpg;

  # ----------------------
  # Packages needed for activation scripts
  # ----------------------
  home.packages = with pkgs; [
    qt6.qttools   # Provides qdbus for KDE activation scripts
  ];

  # ----------------------
  # Desktop wallpaper activation
  # ----------------------
  home.activation.setDesktopWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.qt6.qttools}/bin/qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
      var Desktops = desktops();
      for (i=0;i<Desktops.length;i++){
        d = Desktops[i];
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = Array("Wallpaper","org.kde.image","General");
        d.writeConfig("Image","file://${config.home.homeDirectory}/.wallpaper.jpg");
      }
    '
  '';

  # ----------------------
  # Lock screen wallpaper activation
  # ----------------------
  home.activation.setLockscreenWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/.config
    cat > ${config.home.homeDirectory}/.config/kscreenlockerrc <<EOF
[Greeter]
Wallpaper=${config.home.homeDirectory}/.wallpaper-lock.jpg
EOF
  '';

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
