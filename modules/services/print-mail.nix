# ../../modules/services/print-mail.nix
#
# Email-to-print without Brother's cloud:
#
#   sender -> print@printer.jpc.onl -> Cloudflare Email Routing (subdomain;
#   jpc.onl itself stays on Proton) -> Email Worker print-mail (sender list,
#   ./print-mail/worker.js, pasted in the dashboard) -> print-hook.jpc.onl
#   (tunnel + Access service token) -> this service on 127.0.0.1 -> CUPS.
#
# Prints PDF, text, images (fit to page) and Office/LibreOffice files
# (converted with LibreOffice), A4 duplex; mail without attachments and
# inline signature logos are ignored. Nothing printable -> the Worker bounces
# the mail with the reason. Every job sends an ntfy message and is kept for
# 7 days in /var/lib/private/print-mail/jobs (the .eml + the files).
#
# Defence in depth: the Worker checks the sender (envelope + From), Access
# only lets the Worker's service token through, this service checks the
# shared secret and the From header again.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.printMail;
in
{
  options.myServices.printMail = {
    enable = lib.mkEnableOption "email-to-print receiver (Cloudflare Email Worker -> CUPS)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8196;
      description = "Localhost port; the tunnel's print-hook hostname points here.";
    };

    queue = lib.mkOption {
      type = lib.types.str;
      default = "Brother-HL-L8230CDW";
      description = "CUPS queue to print on.";
    };

    allowedSenders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "From addresses that may print (checked again here, after the Worker).";
    };

    secretAgeFile = lib.mkOption {
      type = lib.types.path;
      description = "agenix file with the shared secret the Worker sends as X-Print-Secret.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.print-mail-secret.file = cfg.secretAgeFile;

    # metric-compatible stand-ins for Calibri, Cambria, Arial, Times, Courier
    fonts.packages = [ pkgs.carlito pkgs.caladea pkgs.liberation_ttf ];

    systemd.services.print-mail = {
      description = "Email-to-print receiver";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "cups.service" ];
      wants = [ "cups.service" ];
      path = [ pkgs.cups pkgs.libreoffice ];
      environment = {
        PM_PORT = toString cfg.port;
        PM_QUEUE = cfg.queue;
        PM_ALLOWED = lib.concatStringsSep "," cfg.allowedSenders;
        PM_HOST = config.networking.hostName;
        PM_NTFY_SERVER = lib.optionalString config.myServices.alerts.enable config.myServices.alerts.server;
      };
      restartTriggers = [ (builtins.hashFile "sha256" cfg.secretAgeFile) ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./print-mail/print-mail.py}";
        DynamicUser = true;
        StateDirectory = "print-mail";
        LoadCredential = [ "secret:${config.age.secrets.print-mail-secret.path}" ]
          ++ lib.optional config.myServices.alerts.enable "ntfy-topic:${config.age.secrets.ntfy-topic.path}";
        Restart = "on-failure";
        MemoryMax = "2G";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        CapabilityBoundingSet = "";
      };
    };

    myServices.alerts.failureUnits = lib.mkIf config.myServices.alerts.enable [ "print-mail" ];
  };
}
