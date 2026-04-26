# ../../modules/services/waydroid.nix
{ config, pkgs, lib, ... }:

{
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    android-tools
    apkeep
  ];
}
