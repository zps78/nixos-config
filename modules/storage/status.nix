# ../../modules/storage/status.nix
#
# ZFS pool status as a tiny JSON file for Homepage's customapi widget:
# health and fill of every pool, the overall state and the oldest last
# scrub. A root timer writes /run/storage-status/status.json every 5 min
# (zpool list/status read ZFS's in-memory state - spun-down disks stay
# down); an unprivileged server publishes it on 127.0.0.1 only. No
# secrets in it. Same pattern as the AirVPN status (vpn-torrent.nix).
#
#   http://127.0.0.1:<port>/status.json
{ config, lib, pkgs, ... }:

let
  cfg = config.myStorage.statusApi;
in
{
  options.myStorage.statusApi = {
    enable = lib.mkEnableOption "ZFS pool status JSON for Homepage";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8189;
      description = "Local-only (127.0.0.1) port of the status JSON.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d /run/storage-status 0755 root root -" ];

    systemd.services.storage-status = {
      description = "Write the ZFS pool status for Homepage";
      serviceConfig.Type = "oneshot";
      path = [ config.boot.zfs.package pkgs.jq pkgs.coreutils pkgs.gnused pkgs.gawk ];
      script = ''
        out=/run/storage-status/status.json
        pools=$(zpool list -H -o name,health,cap,size)
        bad=$(echo "$pools" | awk '$2 != "ONLINE" {printf "%s %s ", $1, $2}')
        status=''${bad:-"all ONLINE"}

        # per pool "ONLINE · 36% of 928G"; scrub "on <date>" / "never" / "running"
        json=$(echo "$pools" | while read -r name health cap size; do
          scan=$(zpool status "$name" | sed -n 's/^ *scan: //p')
          case "$scan" in
            *"scrub in progress"*) scrub="running" ;;
            *"scrub repaired"*)    scrub=$(date -d "$(echo "$scan" | sed -E 's/.* on //')" +%F 2>/dev/null || echo "?") ;;
            *)                     scrub="never" ;;
          esac
          jq -n --arg n "$name" --arg v "$health · $cap of $size" --arg s "$scrub" '{($n): $v, ("scrub_" + $n): $s}'
        done | jq -s 'add')

        oldest=$(echo "$json" | jq -r '[to_entries[] | select(.key|startswith("scrub_")) | .value] | if any(. == "never") then "never (some pools)" else (sort | first) end')
        echo "$json" | jq --arg status "$status" --arg scrub "$oldest" '. + {status: $status, last_scrub: $scrub}' > "$out.new"
        chmod 0644 "$out.new"; mv "$out.new" "$out"
      '';
    };
    systemd.timers.storage-status = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "1min"; OnUnitActiveSec = "5min"; AccuracySec = "30s"; };
    };

    systemd.services.storage-status-http = {
      description = "Serve the ZFS pool status on 127.0.0.1";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -m http.server ${toString cfg.port} --bind 127.0.0.1 --directory /run/storage-status";
        DynamicUser = true;
        Restart = "on-failure";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      };
    };
  };
}
