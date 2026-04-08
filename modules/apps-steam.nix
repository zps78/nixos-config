# ../../modules/apps-streaming.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Development
    # godot
    vscode
    # Streaming
#    obs-studio
    sunshine
    # Gaming
    lutris
    steam
    moonlight-qt
  ];
  # Steam-specific config
  programs.steam.enable = true;
  }
