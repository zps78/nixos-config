# ../../modules/services/vpn-torrent.nix
#
# qBittorrent confined to a WireGuard network namespace (AirVPN), native -
# the NixOS replacement for karma's gluetun + "--network container:airvpn".
# Built on VPN-Confinement (flake input vpn-confinement): the namespace has
# only the tunnel for internet traffic, so nothing leaves via the home
# connection if the tunnel is down.
#
#   web UI   http://<host lanIp>:<webuiPort>   (LAN + Tailscale only, via
#            a port mapping into the namespace)
#   torrent  inbound on the AirVPN forwarded port, on the tunnel only
#
# Needs: an AirVPN *device* of its own for this host (a key in use on two
# machines knocks both off), its WireGuard config in agenix
# (secrets/airvpn-wg.conf.age), and a port forwarded to that device in the
# AirVPN client area (forwardedPort).
#
# Phase-4 groundwork: tested on kraken 2026-11 before anything real depends
# on it. VPN-Confinement's README warns its DNS-leak protection is only
# tested for plain UDP DNS - test leaks after changes.
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.myServices.vpnTorrent;
  ns = "airvpn";                       # namespace name, max 7 characters
in
{
  imports = [ inputs.vpn-confinement.nixosModules.default ];

  options.myServices.vpnTorrent = {
    enable = lib.mkEnableOption "qBittorrent in an AirVPN WireGuard namespace";

    forwardedPort = lib.mkOption {
      type = lib.types.port;
      description = "Port forwarded to this host's AirVPN device (client area -> Ports).";
    };

    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 8180;
      description = "qBittorrent web UI port (inside the namespace and on the host).";
    };

    statusPort = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = ''
        Local-only (127.0.0.1) JSON status of the tunnel for Homepage's
        customapi widget: http://127.0.0.1:<port>/status.json
      '';
    };

    allowedIngress = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.168.1.0/24" "100.64.0.0/10" ];
      description = "Networks that may reach the web UI (LAN + Tailscale).";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.airvpn-wg.file = ../../secrets/airvpn-wg.conf.age;   # root 0400

    vpnNamespaces.${ns} = {
      enable = true;
      wireguardConfigFile = config.age.secrets.airvpn-wg.path;
      allowedIngress = cfg.allowedIngress;
      portMappings = [ { from = cfg.webuiPort; to = cfg.webuiPort; protocol = "tcp"; } ];
      vpn.allowedTCPPorts = [ cfg.forwardedPort ];
      vpn.allowedUDPPorts = [ cfg.forwardedPort ];
    };

    services.qbittorrent = {
      enable = true;
      openFirewall = false;              # the namespace handles its own ports
      webuiPort = cfg.webuiPort;
      torrentingPort = cfg.forwardedPort;
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences.WebUI = {
          Address = "*";                 # inside the namespace: only the mapping reaches it
          Port = cfg.webuiPort;
        };
        BitTorrent.Session = {
          Port = cfg.forwardedPort;
          DisableAutoTMMByDefault = true;
        };
      };
    };

    systemd.services.qbittorrent.vpnConfinement = {
      enable = true;
      vpnNamespace = ns;
    };

    # Tunnel status for Homepage (customapi widget). A root timer reads the
    # tunnel every minute - latest handshake and traffic from `wg`, exit
    # address and country from inside the namespace (refreshed every 10
    # min) - into /run/vpn-status/status.json; a tiny unprivileged server
    # publishes that file on 127.0.0.1 only. No secrets in it.
    environment.systemPackages = [ pkgs.wireguard-tools ];
    systemd.tmpfiles.rules = [ "d /run/vpn-status 0755 root root -" ];

    systemd.services.vpn-status = {
      description = "Write the AirVPN tunnel status for Homepage";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [ iproute2 wireguard-tools curl jq coreutils ];
      script = ''
        out=/run/vpn-status/status.json; cache=/run/vpn-status/exit.json
        if [ -e /run/netns/${ns} ] && dump=$(ip netns exec ${ns} wg show all dump 2>/dev/null) && [ -n "$dump" ]; then
          # peer line: iface pubkey psk endpoint allowed-ips handshake rx tx keepalive
          read -r hs rx tx < <(echo "$dump" | awk 'NF==9 {print $6, $7, $8; exit}')
          now=$(date +%s)
          if [ "''${hs:-0}" -gt 0 ] && [ $((now - hs)) -lt 180 ]; then status=up; else status=stale; fi
          if [ ! -s "$cache" ] || [ $(( now - $(stat -c %Y "$cache") )) -gt 600 ]; then
            ip netns exec ${ns} curl -s -m 10 https://ipinfo.io/json > "$cache.new" && mv "$cache.new" "$cache" || rm -f "$cache.new"
          fi
          jq -n --arg status "$status" --argjson hs "''${hs:-0}" --argjson rx "''${rx:-0}" --argjson tx "''${tx:-0}" \
                --slurpfile exit <(cat "$cache" 2>/dev/null || echo '{}') \
            '{status: $status,
              handshake: (if $hs > 0 then ($hs | todate) else null end),
              rx: $rx, tx: $tx,
              exit_ip: ($exit[0].ip // "?"),
              exit_where: (($exit[0].city // "?") + ", " + ($exit[0].country // "?"))}' > "$out.new"
        else
          jq -n '{status: "down", handshake: null, rx: 0, tx: 0, exit_ip: "-", exit_where: "-"}' > "$out.new"
        fi
        chmod 0644 "$out.new"; mv "$out.new" "$out"
      '';
    };
    systemd.timers.vpn-status = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "1min"; OnUnitActiveSec = "1min"; AccuracySec = "10s"; };
    };

    systemd.services.vpn-status-http = {
      description = "Serve the AirVPN tunnel status on 127.0.0.1";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -m http.server ${toString cfg.statusPort} --bind 127.0.0.1 --directory /run/vpn-status";
        DynamicUser = true;
        Restart = "on-failure";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      };
    };
  };
}
