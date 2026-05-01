# ../../modules/apps/lutris.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lutris
  ];
}
