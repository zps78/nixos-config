# ../../modules/services/filebrowser-quantum.nix
#
# FileBrowser Quantum: web file manager (folder view, previews, search),
# WebDAV, and share links incl. upload links. nixpkgs has the package but
# no NixOS module - this is ours. Runs as its own system user and sees
# only the listed sources (plain files on disk, nothing proprietary).
#
#   http://<lanIp>:<port>    LAN + tailnet (tailscale0 is trusted fleet-wide)
#   <port>/dav/<source>/     WebDAV (password = an API token from the UI)
#   share links              <publicUrl>public/share/<hash> - all public
#                            pages live under /public/ (pages, their API,
#                            static files), so a tunnel that passes only
#                            ^/public/ never exposes the login or /api/.
#
# Config: written to /run at every start from the Nix settings plus the
# admin password from agenix (Quantum has no env var for it). A set
# auth.adminPassword is (re)applied to the admin user at start, so the
# agenix file stays the source of truth.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.filebrowserQuantum;
  stateDir = "/var/lib/filebrowser-quantum";
  runDir = "/run/filebrowser-quantum";

  settings = lib.recursiveUpdate ({
    http = {
      port = cfg.port;
      # the tunnel connects from localhost and sends the visitor's address
      # (rate limits then hit the visitor, not the tunnel)
      trustProxyHeaders = true;
    } // lib.optionalAttrs (cfg.publicUrl != null) { externalUrl = cfg.publicUrl; }
      // lib.optionalAttrs (cfg.office.url != null && cfg.office.selfUrl != null) { internalUrl = cfg.office.selfUrl; };
    server = {
      cacheDir = "/var/cache/filebrowser-quantum";
      disableUpdateCheck = true;
      sources = map (s: {
        inherit (s) path name;
        config = { defaultEnabled = true; } // lib.optionalAttrs s.readOnly { readOnly = true; };
      }) cfg.sources;
    };
    auth = {
      adminUsername = cfg.adminUser;
      adminPassword = "@ADMIN_PASSWORD@";
      methods.password = { enabled = true; minLength = 12; signup = false; };
    };
    frontend = {
      name = config.networking.hostName;
      styling = lib.optionalAttrs (cfg.darkBackground != null) { darkBackground = cfg.darkBackground; }
        // lib.optionalAttrs (cfg.customCss != null) { customCSS = "${pkgs.writeText "filebrowser-quantum.css" cfg.customCss}"; };
    };
    userDefaults.ui = { darkMode = true; } // lib.optionalAttrs (cfg.themeColor != null) { themeColor = cfg.themeColor; };
  } // lib.optionalAttrs (cfg.office.url != null) {
    integrations.office = {
      inherit (cfg.office) url;
      secret = "@OFFICE_SECRET@";
    } // lib.optionalAttrs (cfg.office.internalUrl != null) { inherit (cfg.office) internalUrl; };
  }) cfg.extraSettings;

  # JSON is valid YAML, so the template is plain JSON.
  template = pkgs.writeText "filebrowser-quantum.template.json" (builtins.toJSON settings);
in
{
  options.myServices.filebrowserQuantum = {
    enable = lib.mkEnableOption "FileBrowser Quantum";

    port = lib.mkOption { type = lib.types.port; default = 8095; };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };

    adminUser = lib.mkOption { type = lib.types.str; default = "admin"; };

    adminPasswordFile = lib.mkOption {
      type = lib.types.str;
      example = "config.age.secrets.filebrowser-admin.path";
      description = "agenix file with the admin's password, one line (min. 12 characters).";
    };

    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://files.example.com";
      description = "Public base URL used in share links (the tunnel's hostname), WITHOUT a trailing slash - Quantum adds one (a double slash would also slip past a ^/public/ tunnel filter).";
    };

    sources = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          path = lib.mkOption { type = lib.types.str; };
          readOnly = lib.mkOption { type = lib.types.bool; default = false; };
        };
      });
      default = [ ];
      description = "Folders to serve (each shows up as a source in the sidebar).";
    };

    themeColor = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Accent colour for new users."; };
    darkBackground = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    customCss = lib.mkOption { type = lib.types.nullOr lib.types.lines; default = null; description = "CSS added to every page (share pages too)."; };

    office = {
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "http://192.168.1.10:8097";
        description = "ONLYOFFICE Document Server as the browser reaches it (null = no office editor).";
      };
      internalUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Document Server as Quantum reaches it (e.g. via localhost).";
      };
      selfUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "http://127.0.0.1:${toString cfg.port}";
        description = "Quantum as the Document Server reaches it (http.internalUrl: file downloads and save callbacks).";
      };
      secretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File with the Document Server's JWT secret, one line (read as root at start).";
      };
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Merged into the generated config (Quantum's YAML schema).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.filebrowser = {
      isSystemUser = true;
      group = "filebrowser";
      home = stateDir;
    };
    users.groups.filebrowser = { };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });

    systemd.services.filebrowser-quantum = {
      description = "FileBrowser Quantum";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ template ];
      # never write into a bare mountpoint if a pool isn't mounted
      unitConfig.RequiresMountsFor = map (s: s.path) cfg.sources;
      environment = {
        FILEBROWSER_CONFIG = "${runDir}/config.yaml";
        FILEBROWSER_DATABASE_PATH = "${stateDir}/filebrowser.sqlite";   # "database.db" is reserved for the v1 format
        FILEBROWSER_DISABLE_AUTOMATIC_BACKUP = "true";
      };
      serviceConfig = {
        # root ("+"): only root can read the agenix file. The password is
        # JSON-quoted, so any characters are safe.
        ExecStartPre = "+${pkgs.writeShellScript "filebrowser-quantum-config" ''
          set -eu
          pw=$(${pkgs.coreutils}/bin/head -n1 ${cfg.adminPasswordFile})
          [ -n "$pw" ] || { echo "admin password file is empty" >&2; exit 1; }
          q=$(printf '%s' "$pw" | ${pkgs.jq}/bin/jq -Rs .)
          ${if cfg.office.url != null then ''
            os=$(${pkgs.coreutils}/bin/head -n1 ${cfg.office.secretFile})
            [ -n "$os" ] || { echo "office secret file is empty" >&2; exit 1; }
            oq=$(printf '%s' "$os" | ${pkgs.jq}/bin/jq -Rs .)
            ${pkgs.jq}/bin/jq --argjson pw "$q" --argjson os "$oq" '.auth.adminPassword = $pw | .integrations.office.secret = $os' ${template} > ${runDir}/config.yaml
          '' else ''
            ${pkgs.jq}/bin/jq --argjson pw "$q" '.auth.adminPassword = $pw' ${template} > ${runDir}/config.yaml
          ''}
          ${pkgs.coreutils}/bin/chown filebrowser ${runDir}/config.yaml
          ${pkgs.coreutils}/bin/chmod 0400 ${runDir}/config.yaml
        ''}";
        ExecStart = "${pkgs.filebrowser-quantum}/bin/filebrowser-quantum -c ${runDir}/config.yaml";
        User = "filebrowser";
        # files land as filebrowser:users, group-writable, so zp (in
        # "users") can manage them over SSH/Samba too
        Group = "users";
        UMask = "0002";
        WorkingDirectory = stateDir;
        StateDirectory = "filebrowser-quantum";
        CacheDirectory = "filebrowser-quantum";
        RuntimeDirectory = "filebrowser-quantum";
        RuntimeDirectoryMode = "0700";
        Restart = "on-failure";
        # hardening: sees only its own dirs and the sources
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        ReadWritePaths = map (s: s.path) (lib.filter (s: !s.readOnly) cfg.sources);
        ReadOnlyPaths = map (s: s.path) (lib.filter (s: s.readOnly) cfg.sources);
      };
    };
  };
}
