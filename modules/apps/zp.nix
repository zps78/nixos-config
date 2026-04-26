# ../../modules/apps/zp.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
  ]
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    vscode

   ## Streaming
    # obs-studio
    # sunshine

   ## Internet
    # brave
    # filezilla
    # thunderbird

   ## Gaming
    # lutris
    # steam
    moonlight-qt
    teamviewer

   ## Wine
    winetricks
    wineWow64Packages.staging

   ## Virtualization / Emulation
    # libvirt
    # virt-manager
    # waydroid - > import waydroid.nix on configuration.nix

   ## Office
    onlyoffice-desktopeditors
    xournalpp
  ];
}
