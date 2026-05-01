# ../../modules/apps/bb.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
#   ../../modules/apps/plex.nix
  ];
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    # vscode

   ## Streaming
    # obs-studio

   ## Internet
    # brave
    # filezilla
    # thunderbird

    darktable


   ## Gaming
    lutris
    steam
    # moonlight-qt
    # teamviewer

   ## Wine
    winetricks
    wineWow64Packages.staging

   ## Virtualization / Emulation

    # waydroid - > import waydroid.nix on configuration.nix

   ## Office
    # onlyoffice-desktopeditors
    # xournalpp
  ];
}
