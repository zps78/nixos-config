# ../../modules/system/common.nix
{ config, pkgs, lib, ... }:

{
  # ----------------------------
  # Nix (flakes + new CLI)
  # ----------------------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ----------------------------
  # Networking baseline
  # ----------------------------
  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  # ----------------------------
  # Modern firewall backend
  # ----------------------------
  networking.nftables.enable = lib.mkDefault true;

  # ----------------------------
  # Licensing
  # ----------------------------
  nixpkgs.config.allowUnfree = true;

  # ----------------------------
  # Base system tools
  # ----------------------------
  programs.git.enable = true;
}
