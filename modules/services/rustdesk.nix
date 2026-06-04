# ../../modules/services/rustdesk.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.rustdesk;
in
{
  options.myServices.rustdesk = {
    enable = lib.mkEnableOption "RustDesk remote desktop";

    relay = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run as RustDesk relay/server (hbbs/hbbr)";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open required firewall ports for RustDesk";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      rustdesk
    ];

    # RustDesk client doesn't require services,
    # but relay/server mode does
    services.rustdesk-server = lib.mkIf cfg.relay {
      enable = true;

      # ID server + relay server
      openFirewall = cfg.openFirewall;

      # default ports (RustDesk standard)
      # 21115 TCP (ID)
      # 21116 TCP/UDP (relay)
      # 21117 TCP (web console optional)
    };

    networking.firewall = lib.mkIf (cfg.relay && cfg.openFirewall) {
      allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
      allowedUDPPorts = [ 21116 ];
    };
  };
}
