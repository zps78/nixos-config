# ../../modules/networking/tailscale.nix
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;

  # ----------------------------
  # Needed for --accept-routes to behave properly
  # ----------------------------
    useRoutingFeatures = "client";

  # ----------------------------
  # Not auto-applied in manual mode, but good to keep
  # ----------------------------
    extraUpFlags = [
      "--accept-dns"
      "--accept-routes"
      "--ssh"
    ];
  };

  # ----------------------------
  # Firewall integration
  # ----------------------------
  services.tailscale.openFirewall = true;    # Recommended as often better than: " networking.firewall.trustedInterfaces = [ "tailscale0" ]; "

}
