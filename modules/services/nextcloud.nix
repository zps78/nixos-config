# ../../modules/services/nextcloud.nix
#
# Nextcloud (nixpkgs' services.nextcloud) - the planned successor of
# FileBrowser Quantum: web files + sync clients (kuro, phone, Windows),
# editing through the ONLYOFFICE Document Server (myServices.onlyoffice).
# Photos stay in Immich, documents in Paperless, media in Plex.
#
#   https://<hostName>     nginx + Let's Encrypt (DNS-01 via Cloudflare, so
#                          nothing has to be reachable from the internet)
#
# Phase 1 = tailnet/LAN only: the public DNS record points at the LAN IP
# ("DNS only"), reachable at home and over Tailscale (kraken's subnet
# route). Going public later = a tunnel route + 2FA, nothing here changes.
#
# Data: config/apps in /var/lib/nextcloud (rpool, snapshotted); user files
# + previews in dataDir (its own dataset). Nextcloud owns dataDir - write
# into it only through Nextcloud (web, clients, WebDAV), or run
#   nextcloud-occ files:scan --all
# afterwards. Database: the local PostgreSQL (socket auth). Cache: Redis.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.nextcloud;
  nc = config.services.nextcloud;
  oo = config.myServices.onlyoffice;
in
{
  options.myServices.nextcloud = {
    enable = lib.mkEnableOption "Nextcloud";

    hostName = lib.mkOption { type = lib.types.str; example = "cloud.example.com"; };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Nextcloud's data directory (user files + previews); a dedicated mount.";
    };

    adminUser = lib.mkOption { type = lib.types.str; default = "admin"; };

    adminPassAgeFile = lib.mkOption {
      type = lib.types.path;
      description = "agenix file with the admin password, used only to create the account the first time.";
    };

    phoneRegion = lib.mkOption { type = lib.types.str; default = "PT"; };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open 443 on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.nextcloud-admin.file = cfg.adminPassAgeFile;     # root-only: read by nextcloud-admin-user

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud35;
      hostName = cfg.hostName;
      https = true;
      datadir = cfg.dataDir;
      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "16G";
      config = {
        dbtype = "pgsql";
      };
      settings = {
        default_phone_region = cfg.phoneRegion;
        maintenance_window_start = 2;              # 02:00-06:00 UTC for heavy background jobs
        overwriteprotocol = "https";
        # the ONLYOFFICE app talks to the Document Server on this machine
        allow_local_remote_servers = true;
      };
      extraApps = lib.optionalAttrs oo.enable { inherit (nc.package.packages.apps) onlyoffice; };
      extraAppsEnable = true;
    };

    services.nginx.virtualHosts.${cfg.hostName} = {
      forceSSL = true;
      useACMEHost = cfg.hostName;
    };
    security.acme.certs.${cfg.hostName}.group = "nginx";

    # the data dir is its own dataset: never write into a bare mountpoint
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0750 nextcloud nextcloud -" ];
    systemd.services = {
      nextcloud-setup.unitConfig.RequiresMountsFor = [ cfg.dataDir ];
      phpfpm-nextcloud.unitConfig.RequiresMountsFor = [ cfg.dataDir ];
      nextcloud-cron.unitConfig.RequiresMountsFor = [ cfg.dataDir ];

      # nixpkgs installs without an admin (--disable-admin-user): create ours
      # once, from agenix. Never touches an existing account (password changes
      # happen in Nextcloud). Runs AS nextcloud, so the occ wrapper calls occ
      # directly - via root it would go through sudo, which logs OC_PASS
      # (the password) to the journal. The password arrives as a credential.
      # Nextcloud's minimum is 10 characters.
      nextcloud-admin-user = {
        description = "Create the Nextcloud admin account";
        after = [ "nextcloud-setup.service" ];
        requires = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ (builtins.hashFile "sha256" cfg.adminPassAgeFile) ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "nextcloud";
          Group = "nextcloud";
          LoadCredential = [ "adminpass:${config.age.secrets.nextcloud-admin.path}" ];
        };
        script = ''
          occ=${nc.occ}/bin/nextcloud-occ
          if $occ user:info ${cfg.adminUser} >/dev/null 2>&1; then
            echo "${cfg.adminUser} exists - nothing to do"; exit 0
          fi
          OC_PASS="$(head -n1 "$CREDENTIALS_DIRECTORY/adminpass")"
          export OC_PASS
          $occ user:add --password-from-env --group admin ${cfg.adminUser}
        '';
      };

      # ONLYOFFICE app settings (stored in Nextcloud's database, so set by occ)
      nextcloud-onlyoffice-config = lib.mkIf oo.enable {
        description = "Point Nextcloud's ONLYOFFICE app at the Document Server";
        after = [ "nextcloud-setup.service" ];
        requires = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ (builtins.hashFile "sha256" oo.jwtAgeFile) ];
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          occ=${nc.occ}/bin/nextcloud-occ
          set_() { $occ config:app:set onlyoffice "$1" --value="$2" >/dev/null; }
          set_ DocumentServerUrl "https://${oo.publicHost}/"
          set_ DocumentServerInternalUrl "http://127.0.0.1:${toString oo.port}/"
          set_ StorageUrl "https://${cfg.hostName}/"
          set_ jwt_secret "$(head -n1 ${config.age.secrets.onlyoffice-jwt.path})"
        '';
      };
    };

    assertions = [ {
      assertion = !oo.enable || oo.publicHost != null;
      message = "myServices.nextcloud: the ONLYOFFICE app needs myServices.onlyoffice.publicHost (https).";
    } ];

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: { allowedTCPPorts = [ 443 ]; });

    myServices.alerts.failureUnits = lib.mkIf config.myServices.alerts.enable
      [ "nextcloud-setup" "nextcloud-cron" "phpfpm-nextcloud" "nextcloud-admin-user" "nextcloud-onlyoffice-config" "postgresql" ];
  };
}
