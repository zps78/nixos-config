# ../../modules/services/scrutiny.nix
#
# Scrutiny: SMART disk health with history and failure thresholds. The
# collector (root, reads SMART directly) runs on a schedule and feeds the
# web app; history lives in a local InfluxDB. No login of its own - keep
# it LAN/Tailscale-only.
#
#   http://<host>:8087
#
# Port 8087, not upstream's 8080: 8080 is the classic default of the
# containers that move over later (SABnzbd, qBittorrent, ...).
{ config, lib, ... }:

let
  cfg = config.myServices.scrutiny;
  port = 8087;
in
{
  options.myServices.scrutiny = {
    enable = lib.mkEnableOption "Scrutiny SMART dashboard";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.scrutiny = {
      enable = true;
      openFirewall = false;
      influxdb.enable = true;
      settings.web.listen = {
        host = "0.0.0.0";
        inherit port;
      };
      collector = {
        enable = true;
        schedule = "hourly";   # cheap; SMART reads don't wake/spin anything here
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ port ];
    });
  };
}
