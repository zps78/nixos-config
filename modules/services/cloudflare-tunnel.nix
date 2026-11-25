# ../../modules/services/cloudflare-tunnel.nix
#
# A Cloudflare tunnel managed in the Cloudflare dashboard (Zero Trust ->
# Networks -> Tunnels): kraken only runs `cloudflared tunnel run` with the
# tunnel's token; which public hostnames/paths go to which local service is
# set in the dashboard ("Public Hostnames"). Outbound connection only - no
# port forwarding on the router.
#
# The token is the tunnel's credential (whoever has it can serve the
# hostnames), so it lives in agenix as an environment file:
#   TUNNEL_TOKEN=<token>
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.cloudflareTunnel;
in
{
  options.myServices.cloudflareTunnel = {
    enable = lib.mkEnableOption "Cloudflare tunnel (dashboard-managed, token)";

    tokenEnvFile = lib.mkOption {
      type = lib.types.str;
      example = "config.age.secrets.cloudflare-tunnel.path";
      description = "agenix environment file with TUNNEL_TOKEN=<token>.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflare-tunnel = {
      description = "Cloudflare tunnel";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
        EnvironmentFile = cfg.tokenEnvFile;
        DynamicUser = true;
        Restart = "always";
        RestartSec = 5;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
        LockPersonality = true;
      };
    };
  };
}
