# ../../modules/apps/bb.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
#   ../../modules/apps/plex.nix
    ../../modules/apps/wine.nix
  ];
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    # vscode

   ## Media
    # obs-studio
    # spotify
    # sunshine        # -> import sunshine.nix in configuration.nix

   ## Internet
    # brave
    # filezilla
    # thunderbird

   ## Gaming
      lutris          # -> make sure to also import wine.nix at the top of this file
    # steam           # -> import steam.nix in configuration.nix

   ## Remote access
      moonlight-qt
      teamviewer

   ## Wine
    # wine            # -> import wine.nix at the top of this file

   ## Virtualization / Emulation
    # libvirt         # -> import libvirt.nix in configuration.nix
    # waydroid        # -> import waydroid.nix in configuration.nix

   ## Office
    # onlyoffice-desktopeditors
    # xournalpp
  ];
}
