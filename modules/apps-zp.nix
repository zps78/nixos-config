# ../../modules/apps-streaming.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Streaming
#    obs-studio
    sunshine
  ];
}
