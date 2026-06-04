{ config, pkgs, lib, ... }:

{
  ############################################################
  # RustDesk package
  ############################################################
  environment.systemPackages = with pkgs; [
    rustdesk
  ];

  ############################################################
  # Firewall (required for RustDesk networking)
  ############################################################
  networking.firewall = {
    allowedTCPPorts = [
      21115
      21116
      21117
      21118
      21119
    ];

    allowedUDPPorts = [
      21116
    ];
  };

  ############################################################
  # System-wide RustDesk service (HEADLESS / STABLE MODE)
  ############################################################
  systemd.services.rustdesk = {
    description = "RustDesk Remote Desktop Service (system mode)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
    ];
    requires = [
      "network-online.target"
    ];

    # Ensures network is actually up
    wants = [
      "network-online.target"
    ];

    serviceConfig = {
      Type = "simple";

      # IMPORTANT: use system mode only
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk --service";

      Restart = "always";
      RestartSec = 5;

      # Stability settings (important for long-running daemon)
      KillMode = "mixed";
      TimeoutStopSec = 30;

      # Must be root for unattended access / display capture hooks
      User = "root";

      # Prevent file descriptor exhaustion under heavy sessions
      LimitNOFILE = 100000;

      # Hardening tweaks (safe minimal baseline for RustDesk)
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
