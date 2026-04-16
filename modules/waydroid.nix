# ../../modules/waydroid.nix
{ config, pkgs, ... }:

{
  # Enable Waydroid service properly
  virtualisation.waydroid.enable = true;

  # Android kernel requirements
  boot.kernelModules = [
    "binder_linux"

    # Networking (required for waydroid bridge)
    "ip_tables"
    "iptable_filter"
    "iptable_nat"
    "nf_nat"
    "nf_conntrack"
  ];

  # Ensure kernel has full netfilter support available
  boot.extraModulePackages = with config.boot.kernelPackages; [
    # Some kernels need explicit netfilter modules available
    netfilter_full  # harmless if not used by your kernel
  ];

  # Optional but recommended for stability
  networking.firewall.enable = true;

  # Prevent weird bridge issues
  networking.nftables.enable = false;
}
