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
  # - Tailscale DNS handling (MagicDNS, split DNS)
  # - caching
  #
  # NetworkManager already hands DNS to resolved when it is enabled;
  # setting it explicitly keeps Tailscale split-DNS predictable.
  #

  services.resolved.enable = lib.mkDefault true;
  networking.networkmanager.dns = "systemd-resolved";

  ############################################################
  # Firewall baseline enforcement
  ############################################################

  networking.firewall.enable = lib.mkDefault true;
  networking.nftables.enable = lib.mkDefault true;
}
