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
{ config, lib, inputs, ... }:

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
  };
}
