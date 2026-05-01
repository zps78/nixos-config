# ../../modules/apps/sc.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
    ../../modules/apps/plex.nix
    ../../modules/apps/wine.nix
  ];
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
      godot
      vscode
    # vscodium

   ## Media
    # obs-studio
      spotify
    # sunshine        # -> import sunshine.nix in the host's configuration.nix

   ## Internet
    # brave
    # filezilla
    # thunderbird

   ## Gaming
      lutris          # -> make sure to also import wine.nix at the top of this file
    # steam           # -> import steam.nix in the host's configuration.nix

   ## Remote access
      moonlight-qt
    # remmina
    # teamviewer

   ## Wine
    # wine            # -> import wine.nix at the top of this file

   ## Virtualization / Emulation
    # libvirt         # -> import libvirt.nix in the host's configuration.nix
    # waydroid        # -> import waydroid.nix in the host's configuration.nix

   ## Office
      onlyoffice-desktopeditors
      xournalpp
  ];
}
