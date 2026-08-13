# ../../modules/networking/core.nix
{ lib, ... }:

{
  ############################################################
  # Networking baseline
  ############################################################

  networking.networkmanager.enable = true;

  ############################################################
  # DNS / system integration
  ############################################################
  #
  # systemd-resolved improves:
  # - VPN DNS handling (Tailscale, WireGuard)
  # - split DNS
  # - caching
  #

  services.resolved.enable = lib.mkDefault true;

  ############################################################
  # Firewall baseline enforcement
  ############################################################
  #
  # Server systems should be explicit about firewall backend
  #

  networking.nftables.enable = lib.mkDefault true;
}
