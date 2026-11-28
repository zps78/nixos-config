# ../../modules/services/onlyoffice.nix
#
# ONLYOFFICE Document Server (native, nixpkgs' services.onlyoffice) as the
# office editor for FileBrowser Quantum. LAN + tailnet only, like Quantum:
#
#   http://<lanIp>:<port>      nginx in front of the Document Server; the
#                              browser loads the editor from here
#
# Quantum <-> Document Server talk over localhost both ways (Quantum's
# integrations.office.internalUrl and http.internalUrl), so the Document
# Server must be allowed to fetch from private/loopback addresses
# (allowLocalConnections). Requests are signed with a shared JWT secret.
#
# Not public: Quantum's share links (files.jpc.onl) can't open documents in
# the editor - that would need the Document Server on the tunnel too.
#
# Secrets (agenix, created by the user):
#   jwtAgeFile    one line, the JWT secret (also given to Quantum)
#   nonceAgeFile  one nginx line:  set $secure_link_secret "<random>";
{ config, lib, ... }:

let
  cfg = config.myServices.onlyoffice;
in
{
  options.myServices.onlyoffice = {
    enable = lib.mkEnableOption "ONLYOFFICE Document Server";

    port = lib.mkOption { type = lib.types.port; default = 8097; };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };

    jwtAgeFile = lib.mkOption { type = lib.types.path; };
    nonceAgeFile = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.onlyoffice-jwt = { file = cfg.jwtAgeFile; owner = "onlyoffice"; group = "onlyoffice"; mode = "0440"; };
    age.secrets.onlyoffice-nonce = { file = cfg.nonceAgeFile; owner = "onlyoffice"; group = "onlyoffice"; mode = "0440"; };   # nginx reads it too (in group onlyoffice)

    services.onlyoffice = {
      enable = true;
      hostname = "onlyoffice";                     # vhost name only; served as the default server on cfg.port
      jwtSecretFile = config.age.secrets.onlyoffice-jwt.path;
      securityNonceFile = config.age.secrets.onlyoffice-nonce.path;
      allowLocalConnections = true;                # fetch/save via Quantum on 127.0.0.1
    };

    services.nginx.virtualHosts.onlyoffice = {
      default = true;
      listen = [ { addr = "0.0.0.0"; port = cfg.port; } ];
      # The module's server block, but with $host:$server_port instead of $host: on a
      # non-default port $host drops the port, so the Document Server built
      # links like http://<host>/cache/... (port 80) -> "Download failed".
      extraConfig = lib.mkForce ''
        rewrite ^/$ /welcome/ redirect;
        rewrite ^\/OfficeWeb(\/apps\/.*)$ /${config.services.onlyoffice.package.version}/web-apps$1 redirect;
        rewrite ^(\/web-apps\/apps\/(?!api\/).*)$ /${config.services.onlyoffice.package.version}$1 redirect;

        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Forwarded-Host $host:$server_port;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
      '';
    };

    services.rabbitmq.listenAddress = "127.0.0.1";

    systemd.services.onlyoffice-docservice.restartTriggers = [
      (builtins.hashFile "sha256" cfg.jwtAgeFile)
      (builtins.hashFile "sha256" cfg.nonceAgeFile)
    ];
    systemd.services.nginx.restartTriggers = [ (builtins.hashFile "sha256" cfg.nonceAgeFile) ];

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });

    myServices.alerts.failureUnits = lib.mkIf config.myServices.alerts.enable
      [ "onlyoffice-docservice" "onlyoffice-converter" "nginx" "rabbitmq" ];
  };
}
