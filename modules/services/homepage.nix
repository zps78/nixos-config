# ../../modules/services/homepage.nix
#
# Homepage: the start page - one tile per service, plus live widgets.
# Read-only, no login; keep it LAN/Tailscale-only. Tiles and widgets are
# passed straight through to services.homepage-dashboard (set them in the
# host config); API keys for service widgets go in an agenix
# environmentFile later (the repo is public).
#
#   http://<host>:8082
{ config, lib, ... }:

let
  cfg = config.myServices.homepage;
  port = 8082;
in
{
  options.myServices.homepage = {
    enable = lib.mkEnableOption "Homepage start page";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };

    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.1.5" "karma" ];
      description = "Names/addresses Homepage is opened by (port added automatically) - it rejects others.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = port;
      openFirewall = false;
      allowedHosts = lib.concatStringsSep "," (map (h: "${h}:${toString port}") cfg.hosts);
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ port ];
    });
  };
}
