# ../../modules/services/rustdesk.nix

{ pkgs, ... }:

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

  # -------------------------------------------------
  # RustDesk user service
  # -------------------------------------------------
  systemd.user.services.rustdesk = {
    description = "RustDesk Remote Desktop";

    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
