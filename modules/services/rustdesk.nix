# ../../modules/services/rustdesk.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.rustdesk;
in
{
  options.myServices.rustdesk = {
    enable = lib.mkEnableOption "RustDesk client (Tailscale-first)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 21118;
      description = "RustDesk direct connection port";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open RustDesk port for direct connections";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      rustdesk
    ];

    # Only needed for direct IP / Tailscale usage
    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];

    networking.firewall.allowedUDPPorts =
      lib.mkIf cfg.openFirewall [ 21119 ];
  };
}
