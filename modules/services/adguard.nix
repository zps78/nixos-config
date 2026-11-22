# ../../modules/services/adguard.nix
#
# AdGuard Home - network-wide DNS filtering, replacing the Pi-hole
# container on the Unraid karma. Fully declarative (mutableSettings =
# false): lists, upstreams and allow rules live here, and changes made in
# the web UI are reverted on the next restart. Query log and statistics
# persist in /var/lib/AdGuardHome.
#
#   DNS     <listenAddresses>:53 (UDP + TCP)
#   web UI  http://<host>:<webPort>  (interfaces + Tailscale only)
#
# Upstreams are encrypted (DoH) - the same providers the Pi-hole queried
# in plain UDP. Reverse lookups for LAN addresses go to the router, so the
# query log shows client names.
{ config, lib, ... }:

let
  cfg = config.myServices.adguard;
in
{
  options.myServices.adguard = {
    enable = lib.mkEnableOption "AdGuard Home DNS filter";

    listenAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "192.168.1.10" "100.101.102.10" ];
      description = ''
        Addresses DNS listens on. Specific addresses, not 0.0.0.0:
        systemd-resolved already holds 127.0.0.53:53. Addresses that appear
        later (tailscale0's) work through net.ipv4.ip_nonlocal_bind.
      '';
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "enp4s0" ];
      description = "Open DNS and the web UI on these interfaces (tailscale0 is trusted already).";
    };

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Web UI port.";
    };

    routerAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Router, asked for reverse lookups of LAN addresses (client names).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Bind the tailnet address even before tailscaled has put it on
    # tailscale0 (otherwise AdGuard fails at boot and only recovers on a
    # restart). Harmless for everything else.
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ 53 cfg.webPort ];
      allowedUDPPorts = [ 53 ];
    });

    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      settings = {
        http.address = "0.0.0.0:${toString cfg.webPort}";

        dns = {
          bind_hosts = cfg.listenAddresses;
          port = 53;

          # Pi-hole's upstreams, over DoH. dns10 = Quad9 without its own
          # filtering (= 9.9.9.10). Load-balanced, fastest preferred.
          upstream_dns = [
            "https://dns10.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
            "https://doh.opendns.com/dns-query"
          ];
          upstream_mode = "load_balance";
          bootstrap_dns = [ "9.9.9.10" "149.112.112.10" "1.1.1.1" "1.0.0.1" ];
          fallback_dns = [ "9.9.9.10" "1.1.1.1" ];

          use_private_ptr_resolvers = true;
          local_ptr_upstreams = [ cfg.routerAddress ];

          # Only LAN and tailnet can reach it; the default 20 queries/s per
          # client would throttle busy clients for no gain.
          ratelimit = 0;
          cache_size = 16777216;            # 16 MB
          cache_optimistic = true;          # answer from expired cache, refresh behind
        };

        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
        };

        # Blocklists. The Pi-hole's Pyenb aggregate (4.5M rules, ~94% of
        # its total) blocked binance.com, the Corsair support widget and
        # hundreds of Google/Microsoft/Apple subdomains - replaced
        # 2026-11-22 by HaGeZi (curated, low false positives): Pro for
        # ads/tracking/telemetry, TIF for phishing/scam/malware.
        # StevenBlack dropped - covered by HaGeZi Pro.
        # ids are fixed and never reused: AdGuard caches each list as
        # data/filters/<id>.txt, so a new URL under an old id would keep the
        # old list's contents until the next refresh. Retired: 2 StevenBlack,
        # 3 Pyenb.
        filters = map (f: f // { enabled = true; }) [
          { id = 1; name = "AdGuard DNS filter";  url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"; }
          { id = 4; name = "HaGeZi Multi Pro";    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"; }
          { id = 5; name = "HaGeZi Threat Intel"; url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt"; }
        ];

        # Pi-hole's allowlist (needed for Pyenb; kept as insurance).
        # "@@||x^" = x and its subdomains.
        user_rules = [
          "@@||binance.com^"
          "! Corsair support button (Forethought widget + API), 2026-11-18"
          "@@||solve-widget.forethought.ai^"
          "@@||solve-api.forethought.ai^"
        ];
      };
    };
  };
}
