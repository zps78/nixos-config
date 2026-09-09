# ../../modules/networking/tailscale.nix
{ config, lib, ... }:

{
  options.myNetwork.tailscale.enable =
    lib.mkEnableOption "Tailscale";

  config = lib.mkIf config.myNetwork.tailscale.enable {
    services.tailscale = {
      enable = true;

      # Needed for --accept-routes to behave properly (subnet routes).
      useRoutingFeatures = "client";

      # Only applied automatically when authKeyFile is set; otherwise run
      # `tailscale up` with these flags once, by hand.
      extraUpFlags = [
        "--accept-dns"
        "--accept-routes"
        "--ssh"
      ];

      # Opens the WireGuard listen port (UDP 41641) for the daemon.
      openFirewall = true;
    };

    # Trust inbound traffic on the tailnet interface. openFirewall above
    # only opens the daemon's port, not services reached over tailscale0.
    # Access is still gated by Tailscale ACLs.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
