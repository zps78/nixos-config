# ../../modules/services/cockpit.nix
#
# Cockpit: web control panel - system overview, logs, services, terminal,
# reboot - plus plugins: ZFS (pools/datasets/snapshots), Files, and
# Machines when libvirt is on. Login with a normal user's password
# (PAM); admin actions go through sudo. Root login is refused by
# Cockpit's default disallowed-users.
#
#   https://<host>:9090   (self-signed TLS until the jpc.onl/Caddy step)
#
# Operate here, configure in the repo: changes clicked into Cockpit that
# NixOS manages (services, network, users) are overwritten on rebuild.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.cockpit;
  port = 9090;
in
{
  options.myServices.cockpit = {
    enable = lib.mkEnableOption "Cockpit web control panel";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };

    origins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "https://192.168.1.5:9090" ];
      description = ''
        URLs Cockpit is opened by. Its websocket rejects other origins, so
        list every address/name used in the browser (with port).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      inherit port;
      openFirewall = false;
      allowed-origins = cfg.origins;
      plugins = with pkgs; [
        cockpit-zfs
        cockpit-files
      ] ++ lib.optional config.virtualisation.libvirtd.enable pkgs.cockpit-machines;
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ port ];
    });
  };
}
