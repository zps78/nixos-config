# ../../modules/services/samba.nix
#
# Samba (SMB) shares, declarative. Users are local system accounts with no
# shell and no login - they exist only for SMB; their SMB passwords come
# from agenix files (never in the repo) and are (re)set on every start of
# samba-users.service.
#
#   myServices.samba = {
#     enable = true;
#     interfaces = [ "enp4s0" ];
#     users.scanner.passwordFile = config.age.secrets.samba-scanner.path;
#     shares.paperless = { path = "..."; "valid users" = "scanner"; ... };
#   };
#
# SMB2+ only, no NetBIOS (clients use the IP address). Port 445 is opened
# only on `interfaces` (tailscale0 is trusted fleet-wide anyway); every
# share additionally only allows the LAN, the tailnet and localhost.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.samba;
in
{
  options.myServices.samba = {
    enable = lib.mkEnableOption "Samba file shares";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open SMB (445/tcp) only on these interfaces.";
    };

    allowedNetworks = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1. 100.64.0.0/10 127.";
      description = "Samba 'hosts allow' for every share.";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.passwordFile = lib.mkOption {
          type = lib.types.str;
          description = "File holding the SMB password (one line) - an agenix secret.";
        };
      });
      default = { };
      description = "SMB-only accounts (system users without shell) and their password files.";
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      description = "Shares: name -> Samba share settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mapAttrs (name: _: {
      isSystemUser = true;
      group = "users";
      description = "SMB-only account";
      shell = "${pkgs.shadow}/bin/nologin";
    }) cfg.users;

    services.samba = {
      enable = true;
      openFirewall = false;
      nmbd.enable = false;               # no NetBIOS browsing - clients use the IP
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = config.networking.hostName;
          "server min protocol" = "SMB2_10";
          "map to guest" = "never";
          "restrict anonymous" = "2";
          "hosts allow" = cfg.allowedNetworks;
          "hosts deny" = "ALL";
          "disable netbios" = "yes";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        };
      } // cfg.shares;
    };

    # SMB passwords from the agenix files, set at every start (so a changed
    # secret applies after a rebuild/restart).
    systemd.services.samba-users = lib.mkIf (cfg.users != { }) {
      description = "Set Samba passwords from agenix";
      after = [ "samba-smbd.service" ];
      wants = [ "samba-smbd.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = lib.mapAttrsToList (_: u: u.passwordFile) cfg.users;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.services.samba.package ];
      script = lib.concatStrings (lib.mapAttrsToList (name: u: ''
        pw=$(head -n1 ${u.passwordFile})
        printf '%s\n%s\n' "$pw" "$pw" | smbpasswd -s -a ${name} >/dev/null
        smbpasswd -e ${name} >/dev/null
        echo "SMB password set for ${name}"
      '') cfg.users);
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ 445 ];
    });
  };
}
