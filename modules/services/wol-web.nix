# ../../modules/services/wol-web.nix
#
# wol-web: one-click Wake-on-LAN over HTTP, for Homepage tiles. Opening
#
#   http://<host>:8089/wake/<name>
#
# sends the magic packet to that machine and returns a one-line page;
# http://<host>:8089/ lists the machines. A GET does the work on purpose:
# a Homepage tile can only open a link. No login - the worst anyone who
# reaches the port can do is wake a PC - so keep it LAN/Tailscale-only.
#
# Python stdlib only (no wakeonlan package), DynamicUser, no capabilities:
# a UDP broadcast needs none.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.wolWeb;
  port = 8089;

  machinesJson = pkgs.writeText "wol-web-machines.json" (builtins.toJSON cfg.machines);

  script = pkgs.writeText "wol-web.py" ''
    import html, json, os, re, socket
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    MACHINES = json.load(open(os.environ["WOL_MACHINES"]))
    BROADCAST = os.environ["WOL_BROADCAST"]
    SOURCE = os.environ.get("WOL_SOURCE", "")
    PORT = int(os.environ["WOL_PORT"])

    def wake(mac):
        raw = bytes.fromhex(re.sub(r"[^0-9a-fA-F]", "", mac))
        assert len(raw) == 6, mac
        packet = b"\xff" * 6 + raw * 16
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            if SOURCE:
                s.bind((SOURCE, 0))
            for p in (9, 7):
                s.sendto(packet, (BROADCAST, p))

    PAGE = ('<!doctype html><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width">'
            '<title>wol</title>'
            '<body style="font:16px system-ui;margin:2em">{}</body>')

    class Handler(BaseHTTPRequestHandler):
        def reply(self, code, body):
            data = PAGE.format(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            path = self.path.split("?", 1)[0].rstrip("/")
            if path == "":
                items = "".join(
                    f'<li><a href="/wake/{html.escape(n)}">{html.escape(n)}</a></li>'
                    for n in sorted(MACHINES))
                return self.reply(200, f"<h3>Wake-on-LAN</h3><ul>{items}</ul>")
            m = re.fullmatch(r"/wake/([A-Za-z0-9._-]+)", path)
            if not m or m.group(1) not in MACHINES:
                return self.reply(404, "unknown machine")
            name = m.group(1)
            try:
                wake(MACHINES[name])
            except OSError as e:
                return self.reply(500, f"failed to wake {html.escape(name)}: {html.escape(str(e))}")
            self.log_message("woke %s (%s)", name, MACHINES[name])
            self.reply(200, f"Magic packet sent to <b>{html.escape(name)}</b>. "
                            "It should be up in a minute or so.")

    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
  '';
in
{
  options.myServices.wolWeb = {
    enable = lib.mkEnableOption "one-click Wake-on-LAN over HTTP";

    machines = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}");
      default = { };
      example = { kimi = "98:fa:9b:01:58:9b"; };
      description = "Name -> MAC. The name is the URL path: /wake/<name>.";
    };

    broadcast = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.255";
      description = "Where the magic packet is sent (the LAN's broadcast address).";
    };

    sourceAddress = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Send from this local address (picks the NIC on multi-NIC hosts). Empty: kernel's choice.";
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the port only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.wol-web = {
      description = "One-click Wake-on-LAN over HTTP";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        WOL_MACHINES = "${machinesJson}";
        WOL_BROADCAST = cfg.broadcast;
        WOL_SOURCE = cfg.sourceAddress;
        WOL_PORT = toString port;
        PYTHONUNBUFFERED = "1";
      };
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -I ${script}";
        Restart = "on-failure";
        DynamicUser = true;
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ port ];
    });
  };
}
