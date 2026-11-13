# ../../modules/networking/tailscale.nix
{ config, lib, pkgs, ... }:

let
  # Home LAN, advertised to the tailnet as a subnet route by karma.
  homeSubnet = "192.168.1.0/24";
  # Home router's MAC - how "am I at home?" is decided. Read at runtime
  # from an agenix secret (secrets/home-gateway-mac.age) so it stays out
  # of the public repo; re-encrypt it if the router is replaced. If the
  # secret is missing, the host is treated as away (today's behaviour).
  homeGatewayMacFile = config.age.secrets.home-gateway-mac.path;
  rulePriority = "5200";  # ahead of tailscale's own rules (5210+)

  # With --accept-routes, tailscale puts karma's 192.168.1.0/24 route in
  # table 52, whose ip rule (5270) is checked before the main table. So
  # even when a host sits ON the home LAN, LAN traffic goes into
  # tailscale0 instead of out the NIC: inbound LAN connections to it die
  # (replies leave via the tunnel - krieger was unreachable on its LAN IP),
  # local transfers detour through karma, and a tailscale hiccup takes the
  # LAN down with it.
  #
  # Fix: while the default gateway is the home router, prefer the main
  # table for the home subnet. suppress_prefixlength 0 ignores main's
  # default route, so this only matches the directly connected /24.
  # Elsewhere the rule is removed, keeping today's behaviour away from
  # home - including on foreign networks that also use 192.168.1.0/24,
  # where the home subnet stays reachable via karma.
  # Re-evaluated on every NetworkManager event (up/down/dhcp/roam).
  homeLanRule = pkgs.writeShellScript "tailscale-home-lan-rule" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.iproute2 pkgs.iputils pkgs.gawk pkgs.gnugrep pkgs.util-linux ]}
    home=0
    mac=$(tr -d '[:space:]' < ${homeGatewayMacFile} 2>/dev/null)
    if [ -n "$mac" ]; then
      for gw in $(ip -4 route show default | awk '{print $3}'); do
        ip neigh show "$gw" | grep -qi "lladdr $mac" || ping -c1 -W1 "$gw" >/dev/null 2>&1
        ip neigh show "$gw" | grep -qi "lladdr $mac" && home=1
      done
    fi
    present=$(ip rule show pref ${rulePriority} | grep -c "to ${homeSubnet}")
    if [ "$home" = 1 ] && [ "$present" = 0 ]; then
      ip rule add pref ${rulePriority} to ${homeSubnet} lookup main suppress_prefixlength 0
      logger -t tailscale-home-lan "home network: ${homeSubnet} via LAN"
    elif [ "$home" = 0 ] && [ "$present" != 0 ]; then
      while ip rule del pref ${rulePriority} 2>/dev/null; do :; done
      logger -t tailscale-home-lan "away: ${homeSubnet} via tailscale"
    fi
  '';
in
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

    age.secrets.home-gateway-mac = {
      file = ../../secrets/home-gateway-mac.age;
      mode = "0400";  # root only; the dispatcher runs as root
    };

    # See homeLanRule above. Every host here uses NetworkManager.
    networking.networkmanager.dispatcherScripts = [
      { type = "basic"; source = homeLanRule; }
    ];
  };
}
