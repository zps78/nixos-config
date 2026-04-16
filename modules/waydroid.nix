{ config, pkgs, ... }:

{
  # Waydroid service
  virtualisation.waydroid.enable = true;

  # Required kernel modules (THIS is the real fix for your log)
  boot.kernelModules = [
    "binder_linux"

    "ip_tables"
    "iptable_filter"
    "iptable_nat"
    "nf_nat"
    "nf_conntrack"
  ];

  # Optional but safe (avoids nftables conflicts in some setups)
  networking.nftables.enable = false;
}
