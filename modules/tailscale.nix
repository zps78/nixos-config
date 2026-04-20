# ../../modules/tailscale.nix
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;

    # Needed for --accept-routes to behave properly
    useRoutingFeatures = "client";

    # Not auto-applied in manual mode, but good to keep
    extraUpFlags = [
      "--accept-dns"
      "--accept-routes"
      "--ssh"
    ];
  };

  # Let Tailscale + systemd-resolved manage DNS cleanly
  services.resolved.enable = true;

  # Firewall: trust Tailscale network
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Modern networking backend (recommended)
  networking.nftables.enable = true;

  # Optional: faster boot
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  # CLI
  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
