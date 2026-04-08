# ../../modules/apps-zp.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  # Development
#    godot
    vscode

  # Streaming
#    obs-studio
#    sunshine

  # Gaming
#    lutris
#    steam
    moonlight-qt
    teamviewer

  # Wine
    winetricks
    wineWow64Packages.staging

  # Virtualization / Emulation
#    libvirt
#    virt-manager
#    waydroid

  ];
  # Steam-specific config
#    programs.steam.enable = true;
}
