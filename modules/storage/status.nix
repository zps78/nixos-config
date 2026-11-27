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
    arrayPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "disk1" "disk2" ];
      description = ''
        Pools that form one media array (single-disk pools under mergerfs).
        They get one combined line ("array": health, fill of all of them)
        and their own oldest scrub ("array_scrub"), and are left out of
        "last_scrub" - their scrub schedule differs (quarterly).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d /run/storage-status 0755 root root -" ];

    systemd.services.storage-status = {
      description = "Write the ZFS pool status for Homepage";
      serviceConfig.Type = "oneshot";
      path = [ config.boot.zfs.package pkgs.jq pkgs.coreutils pkgs.gnused pkgs.gawk config.systemd.package ];
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

        # oldest scrub, "never" wins; array pools separately
        arr='${builtins.toJSON cfg.arrayPools}'
        oldestOf() { echo "$json" | jq -r --argjson arr "$arr" --argjson inArr "$1" '
          [to_entries[] | select(.key|startswith("scrub_")) | select(((((.key|ltrimstr("scrub_")) as $p | $arr | index($p)) != null)) == $inArr) | .value]
          | if length == 0 then "-" elif any(. == "never") then "never (some pools)" else (sort | first) end'; }
        oldest=$(oldestOf false)
        extra='{}'
        if [ "$arr" != "[]" ]; then
          # combined line: "5 ONLINE · 45% of 72.5T" (or the pools that aren't)
          line=$(zpool list -Hp -o name,health,alloc,size | jq -R -s -r --argjson arr "$arr" '
            [split("\n")[] | select(length > 0) | split("\t") | select(.[0] as $p | $arr | index($p))]
            | (map(select(.[1] != "ONLINE") | "\(.[0]) \(.[1])") | join(" ")) as $bad
            | (map(.[2]|tonumber) | add) as $a | (map(.[3]|tonumber) | add) as $s
            | (if $bad == "" then "\(length) ONLINE" else $bad end)
              + " · \(($a * 100 / $s) | floor)% of \(($s / 1099511627776 * 10 | round) / 10)T"')
          extra=$(jq -n --arg l "$line" --arg s "$(oldestOf true)" '{array: $l, array_scrub: $s}')
        fi
        ${lib.optionalString config.services.snapraid.enable ''
        # SnapRAID: the last sync from systemd (snapraid status would read all disks)
        st=$(systemctl show snapraid-sync -p ActiveState --value)
        res=$(systemctl show snapraid-sync -p Result --value)
        ts=$(systemctl show snapraid-sync -p ExecMainExitTimestamp --value)
        if [ "$st" = activating ] || [ "$(systemctl show snapraid-first-sync -p ActiveState --value 2>/dev/null)" = active ]; then snap="sync running"
        elif [ -z "$ts" ] || [ "$ts" = n/a ]; then snap="never synced"
        elif [ "$res" = success ]; then snap="synced $(date -d "$ts" "+%F %H:%M")"
        else snap="FAILED $(date -d "$ts" "+%F %H:%M")"; fi
        extra=$(echo "$extra" | jq --arg s "$snap" '. + {snapraid: $s}')
        ''}
        echo "$json" | jq --arg status "$status" --arg scrub "$oldest" --argjson extra "$extra" '. + {status: $status, last_scrub: $scrub} + $extra' > "$out.new"
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
