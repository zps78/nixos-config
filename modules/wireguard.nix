# ../../modules/wireguard.nix
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    networkmanager-wireguard
  ];
}

# Per-machine setup (manual, once)
#
# Step 1 — Import your AirVPN config
# nmcli connection import type wireguard file airvpn.conf
#
# Step 2 — Apply these critical fixes
#
#  1. Make AirVPN the default route
# nmcli connection modify airvpn ipv4.never-default no
# nmcli connection modify airvpn ipv6.never-default no
#
#  2. Prevent DNS conflicts (VERY important)
# nmcli connection modify airvpn ipv4.ignore-auto-dns yes
# nmcli connection modify airvpn ipv6.ignore-auto-dns yes

#  3. Set route priority (so AirVPN always wins internet)
# nmcli connection modify airvpn ipv4.route-metric 50
# nmcli connection modify "Wired connection 1" ipv4.route-metric 100
# nmcli connection modify "Wi-Fi connection" ipv4.route-metric 200
#
