# ../../modules/apps-steam.nix
{ config, pkgs, ... }:

{
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    # vscode

   ## Streaming
    # obs-studio
    sunshine

   ## Internet
    # brave
    # filezilla
    # thunderbird

   ## Gaming
    lutris
    steam
    # moonlight-qt
    # teamviewer

   ## Wine
    winetricks
    wineWow64Packages.staging

   ## Virtualization / Emulation
    # libvirt
    # virt-manager
    # waydroid

   ## Office
    # onlyoffice-desktopeditors
    # xournalpp
  ];

  # ----------------------
  # Programs
  # ----------------------
  programs.firefox.enable = true;
  programs.steam.enable = true;
}
