# ../../modules/apps/zp.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
#   ../../modules/apps/lutris.nix
    ../../modules/apps/plex.nix
#   ../../modules/apps/steam.nix
    ../../modules/apps/wine.nix
    ];
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    vscode

   ## Streaming
    # obs-studio
    # sunshine       - > import sunshine.nix in configuration.nix

   ## Internet
    # filezilla
    # thunderbird

   ## Gaming
    # lutris          -> import lutris.nix at the top of this file
    # steam           -> import steam.nix at the top of this file
    moonlight-qt
    teamviewer

   ## Wine
    # wine            -> import wine.nix at the top of this file


   ## Virtualization / Emulation
    # libvirt         -> import libvirt.nix in configuration.nix
    # waydroid       - > import waydroid.nix in configuration.nix

   ## Office
    onlyoffice-desktopeditors
    xournalpp
  ];
}
