# ../../modules/services/copyparty.nix
#
# copyparty: web file browser + resumable uploads + WebDAV + share links,
# one Python program (nixpkgs has the package, no NixOS module - this is
# ours). Runs as its own system user and sees only the volumes listed here.
#
#   http://<lanIp>:<port>    LAN + tailnet (tailscale0 is trusted fleet-wide)
#   WebDAV                   same address (mount as a network drive)
#   share links              <publicUrl>/shr/<id> - created in the web UI by
#                            users with the "a" permission; published through
#                            the Cloudflare tunnel (myServices.cloudflareTunnel),
#                            which passes ONLY /shr/ and /.cpr/ (static files),
#                            so the login page itself is never public.
#
# Accounts come from an agenix file (the repo is public), included verbatim:
#   [accounts]
#     zp: <password>
# Volume data (search index, thumbnails) lives on the system SSD under
# /var/lib/copyparty, so browsing doesn't write to the HDD pools.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.copyparty;

  volumeSection = mount: v: ''
    [${mount}]
      ${v.path}
      accs:
    ${lib.concatStrings (lib.mapAttrsToList (perm: users: "    ${perm}: ${lib.concatStringsSep ", " users}\n") v.access)}
  '';

  configFile = pkgs.writeText "copyparty.conf" ''
    [global]
      p: ${toString cfg.port}
      name: ${config.networking.hostName}
      hist: /var/lib/copyparty/hist
      no-robots
      # the tunnel connects from localhost and sends the visitor's address
      xff-src: 127.0.0.1/32, ::1/128
      rproxy: 1
      # share links: who may create them, and the public address they use
      shr: /shr
      shr-who: a
      ${lib.optionalString (cfg.publicUrl != null) "shr-site: ${cfg.publicUrl}"}
      # 3 wrong passwords in 60 min = banned for a day
      ban-pw: 3,60,1440
      e2d
      ${cfg.extraGlobal}

    % ${cfg.accountsFile}

    ${lib.concatStrings (lib.mapAttrsToList volumeSection cfg.volumes)}
  '';
in
{
  options.myServices.copyparty = {
    enable = lib.mkEnableOption "copyparty file browser";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3923;
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };

    accountsFile = lib.mkOption {
      type = lib.types.str;
      example = "config.age.secrets.copyparty-accounts.path";
      description = "agenix file with an [accounts] section, included into the config.";
    };

    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://files.example.com/";
      description = "Public base URL for share links (the tunnel's hostname).";
    };

    volumes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption { type = lib.types.str; description = "Directory on disk."; };
          access = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            example = { rwmda = [ "zp" ]; };
            description = ''
              copyparty permission letters -> users. r read, w write,
              m move, d delete, a admin (also: may create share links),
              g get-only, h get + folder html. Everyone else: nothing.
            '';
          };
          writable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Let the service write here (ReadWritePaths).";
          };
        };
      });
      default = { };
      description = "URL path (\"/files\") -> volume.";
    };

    extraGlobal = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra [global] lines.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.copyparty = {
      isSystemUser = true;
      group = "copyparty";
      home = "/var/lib/copyparty";
    };
    users.groups.copyparty = { };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });

    systemd.services.copyparty = {
      description = "copyparty file browser";
      after = [ "network.target" ];
      # never write into the bare mountpoint if a pool isn't mounted
      unitConfig.RequiresMountsFor = lib.mapAttrsToList (_: v: v.path) cfg.volumes;
      wantedBy = [ "multi-user.target" ];
      # restart when the config changes (accounts: restartTriggers on the host)
      restartTriggers = [ configFile ];
      environment = {
        XDG_CONFIG_HOME = "/var/lib/copyparty/.config";
        PYTHONUNBUFFERED = "1";
      };
      serviceConfig = {
        ExecStart = "${pkgs.copyparty}/bin/copyparty -c ${configFile}";
        User = "copyparty";
        # files land as copyparty:users, group-writable, so zp (in "users")
        # can manage them over SSH/Samba too
        Group = "users";
        UMask = "0002";
        StateDirectory = "copyparty";
        Restart = "on-failure";
        # hardening: sees only its state dir and the volumes
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
        ReadWritePaths = lib.mapAttrsToList (_: v: v.path) (lib.filterAttrs (_: v: v.writable) cfg.volumes);
        ReadOnlyPaths = lib.mapAttrsToList (_: v: v.path) (lib.filterAttrs (_: v: !v.writable) cfg.volumes);
      };
    };
  };
}
