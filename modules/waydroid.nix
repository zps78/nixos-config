#../../modules/waydroid.nix
{ config, pkgs, lib, ... }:

{
  networking.nftables.enable = true;
  virtualisation.waydroid.enable = true;
}
