# ../../modules/apps-zp.nix
{ config, pkgs, ... }:

{
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
    firefox
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
    waydroid

   ## Office
    onlyoffice-desktopeditors
    xournalpp
  ];

  # ----------------------
  # Programs
  # ----------------------
  programs.firefox.enable = true;
  virtualisation.waydroid.enable = true;
}
