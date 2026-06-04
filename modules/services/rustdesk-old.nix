{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    rustdesk
  ];

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

  systemd.services.rustdesk = {
    description = "RustDesk Remote Desktop Service";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" "display-manager.service" ];
    wantedBy = [ "graphical.target" ];

    path = with pkgs; [
      rustdesk
      procps
      gawk
      gnugrep
      findutils
      bash
      coreutils
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk --service";
      Restart = "always";
      RestartSec = 5;
      KillMode = "mixed";
      TimeoutStopSec = 30;
      User = "root";
      LimitNOFILE = "100000";
    };
  };
}
