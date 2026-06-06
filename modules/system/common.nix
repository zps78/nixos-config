# ../../modules/system/common.nix
{ config, pkgs, lib, ... }:


{
  ############################################################
  # Nix core system behavior (ALL hosts)
  ############################################################

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################################################
  # Base system utilities (safe everywhere)
  ############################################################

  programs.git.enable = true;
  services.fwupd.enable = true;
}
