# ../../modules/services/rustdesk.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.rustdesk;
in
{
  options.myServices.rustdesk = {
    enable = lib.mkEnableOption "RustDesk client";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rustdesk-flutter;
      description = "RustDesk package to use";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open ports for direct connections";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 21118;
      description = "RustDesk TCP port (direct mode)";
    };

    udpPort = lib.mkOption {
      type = lib.types.port;
      default = 21119;
      description = "RustDesk UDP port (NAT traversal / direct)";
    };

    runService = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run RustDesk system service (--service mode)";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      cfg.package
    ];

    # Optional system service mode (headless / always-on host)
    systemd.services.rustdesk = lib.mkIf cfg.runService {
      description = "RustDesk Remote Desktop Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/rustdesk --service";
        Restart = "always";
        RestartSec = 5;
        User = "root";
        LimitNOFILE = 100000;
      };
    };

    # Firewall (FIXED: proper conditional merging)
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.udpPort ];
    };
  };
}