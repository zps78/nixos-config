# ../../modules/services/alerts.nix
#
# Push alerts to the phone via ntfy.sh (layer 2 of the alerting plan -
# declarative; Beszel's thresholds are layer 1, set in its UI).
#
#   ZFS (ZED)   pool state changes, scrub/resilver results, I/O and
#               checksum errors - OpenZFS's own ntfy support
#   smartd      SMART warnings and failed self-tests, on every disk
#   systemd     "unit failed" for the units listed in failureUnits
#
# The topic is the only protection on ntfy.sh (whoever knows it can read
# and post), so it's random and lives in agenix (secrets/ntfy-topic.age),
# read at send time - it never reaches the nix store. Subscribe to it in
# the ntfy app; get it with
#   cd secrets && nix run github:ryantm/agenix -- -d ntfy-topic.age -i ~/.ssh/id_ed25519
#
# Test from the host:  sudo systemctl start ntfy-test
# By hand:             echo "body" | sudo ntfy-send "title" [priority] [tags]
#
# Can't report its own host being down or offline - that needs a check
# from another machine.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.alerts;
  host = config.networking.hostName;
  topicFile = config.age.secrets.ntfy-topic.path;

  # ntfy-send TITLE [PRIORITY] [TAGS] < body
  ntfySend = pkgs.writeShellApplication {
    name = "ntfy-send";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      title="${host}: ''${1:?usage: ntfy-send TITLE [PRIORITY] [TAGS] < body}"
      prio="''${2:-default}"
      tags="''${3:-}"
      topic="$(cat ${topicFile})"
      body="$(cat)"
      [ -n "$body" ] || body="$title"
      curl -fsS -m 20 --retry 3 --retry-delay 5 -o /dev/null \
        -H "Title: $title" -H "Priority: $prio" -H "Tags: $tags" \
        --data-binary "$body" "${cfg.server}/$topic"
    '';
  };

  smartdNotify = pkgs.writeShellScript "smartd-ntfy" ''
    printf '%s\n\n%s\n' "$SMARTD_FAILTYPE on $SMARTD_DEVICESTRING" "$SMARTD_FULLMESSAGE" \
      | ${ntfySend}/bin/ntfy-send "SMART: $SMARTD_DEVICESTRING" high warning,floppy_disk
  '';
in
{
  options.myServices.alerts = {
    enable = lib.mkEnableOption "ntfy push alerts (ZED, smartd, failed units)";

    server = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.sh";
      description = "ntfy server base URL.";
    };

    failureUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "zfs-zed" "smartd" ];
      description = "System services (names without .service) that send an alert when they fail.";
    };

    heartbeatUrlFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "config.age.secrets.heartbeat-url.path";
      description = ''
        File with a dead-man's-switch ping URL (healthchecks.io), one line.
        The host GETs it every heartbeatInterval; when the pings stop (host
        down, no power, no internet) the external service alerts - the one
        failure the host can't report itself. The URL is the only protection
        (whoever has it can ping), so it lives in agenix.
      '';
    };

    heartbeatInterval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "How often to ping (match the check's period on healthchecks.io).";
    };

    healthchecks = {
      pingKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "config.age.secrets.healthchecks-ping-key.path";
        description = ''
          File with the healthchecks.io project's ping key, one line. Each
          job in `checks` then pings https://hc-ping.com/<key>/<slug> when it
          finishes successfully; ?create=1 creates the check on its first
          ping (set its schedule on healthchecks.io afterwards). Catches jobs
          that silently stop running, which OnFailure can't. In agenix:
          whoever has the key can ping (and create checks).
        '';
      };
      checks = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { sanoid = "kraken-snapshots"; };
        description = "System service (name without .service) -> check slug, pinged on success.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.ntfy-topic.file = ../../secrets/ntfy-topic.age;   # root 0400

    environment.systemPackages = [ ntfySend ];

    # ZED sources zed.rc as a shell script, so the topic is read from the
    # secret when ZED runs. Not VERBOSE: ZED only reports problems (faults,
    # a scrub with errors), immediately and per pool. Clean scrubs get one
    # summary for all pools instead (zfs-scrub-report below).
    services.zfs.zed.settings = {
      ZED_NTFY_TOPIC = "$(cat ${topicFile})";
      ZED_NTFY_URL = cfg.server;
      ZED_NOTIFY_VERBOSE = lib.mkForce 0;
      ZED_NOTIFY_INTERVAL_SECS = 3600;   # same event class at most hourly
    };

    # smartd: our script instead of the NixOS notifications (wall to
    # logged-in terminals). Short self-test daily 02:00, long Sundays 04:00.
    services.smartd = {
      notifications.wall.enable = false;
      defaults.monitored = "-a -s (S/../.././02|L/../../7/04) -m <nomailer> -M exec ${smartdNotify}";
    };

    # "unit failed": an OnFailure hook on each listed unit.
    systemd.services = lib.mkMerge [ ({
      "ntfy-failure@" = {
        description = "ntfy alert: %i failed";
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        path = [ ntfySend config.systemd.package ];
        script = ''
          journalctl -u "$1" -n 15 --no-pager -o cat | ntfy-send "$1 failed" high rotating_light
        '';
      };

      ntfy-test = {
        description = "ntfy alert test (start by hand)";
        serviceConfig.Type = "oneshot";
        path = [ ntfySend ];
        script = ''
          echo "Test alert. ZED, smartd and failed-unit alerts from ${host} go to this topic." \
            | ntfy-send "test" default white_check_mark
        '';
      };
    } // lib.optionalAttrs (cfg.heartbeatUrlFile != null) {
      # Dead-man's switch: "I'm alive" to healthchecks.io (timer below).
      # curl retries a few times so a brief network hiccup doesn't cost a
      # ping; a missing or malformed secret just logs and skips.
      heartbeat = {
        description = "Ping the external down-check (healthchecks.io)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig.Type = "oneshot";
        path = [ pkgs.curl pkgs.coreutils ];
        script = ''
          url=$(head -n1 ${cfg.heartbeatUrlFile})
          case "$url" in
            https://*) ;;
            *) echo "heartbeat: secret is not an https:// URL - not pinging" >&2; exit 0 ;;
          esac
          # every error retried (not only timeouts), then once more over IPv4:
          # a flaky IPv6 path failed in milliseconds and raised false "down"
          # alerts (2026-11-27)
          curl -fsS -m 10 --retry 3 --retry-delay 5 --retry-all-errors -o /dev/null "$url" \
            || curl -4 -fsS -m 10 --retry 2 --retry-delay 5 --retry-all-errors -o /dev/null "$url"
        '';
      };
    } // lib.optionalAttrs (cfg.healthchecks.pingKeyFile != null && cfg.healthchecks.checks != { }) {
      # "job finished" ping, %i = check slug (see healthchecks.checks).
      "hc-ping@" = {
        description = "healthchecks.io: %i finished";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        path = [ pkgs.curl pkgs.coreutils ];
        script = ''
          key=$(head -n1 ${cfg.healthchecks.pingKeyFile})
          [ -n "$key" ] || { echo "hc-ping: empty ping key - not pinging" >&2; exit 0; }
          u="https://hc-ping.com/$key/$1?create=1"
          curl -fsS -m 10 --retry 3 --retry-delay 5 --retry-all-errors -o /dev/null "$u" \
            || curl -4 -fsS -m 10 --retry 2 --retry-delay 5 --retry-all-errors -o /dev/null "$u"
        '';
      };
    })
    # One ntfy summary when the monthly scrub job is done (zpool scrub -w:
    # after ALL pools finished) - health, repaired, duration, errors per
    # pool. High priority if any pool isn't ONLINE or had errors.
    (lib.optionalAttrs config.services.zfs.autoScrub.enable {
      zfs-scrub.onSuccess = [ "zfs-scrub-report.service" ];
      zfs-scrub-report = {
        description = "ntfy summary of the finished ZFS scrub";
        serviceConfig.Type = "oneshot";
        path = [ config.boot.zfs.package ntfySend pkgs.gnused pkgs.coreutils ];
        script = ''
          body=""; bad=0
          for p in $(zpool list -H -o name); do
            health=$(zpool list -H -o health "$p")
            scan=$(zpool status "$p" | sed -n 's/^ *scan: //p')
            errors=$(echo "$scan" | sed -nE 's/^scrub repaired .* with ([0-9]+) errors.*/\1/p')
            line=$(echo "$scan" | sed -E 's/^scrub repaired ([^ ]+) in ([^ ]+) with ([0-9]+) errors.*/\3 errors, repaired \1, took \2/')
            if [ "$health" != ONLINE ] || [ "''${errors:-x}" != 0 ]; then bad=1; fi
            body="$body$p: $health, $line"$'\n'
          done
          if [ "$bad" = 0 ]; then
            printf '%s' "$body" | ntfy-send "scrub done: all pools clean" default white_check_mark,floppy_disk
          else
            printf '%s' "$body" | ntfy-send "scrub done: PROBLEMS" high warning,floppy_disk
          fi
        '';
      };
    })
    # Per-unit hooks, merged (not //): a unit can be in both lists -
    # zfs-scrub alerts on failure AND pings on success.
    (lib.genAttrs cfg.failureUnits (_: {
      onFailure = [ "ntfy-failure@%n.service" ];
    }))
    (lib.mapAttrs (_: slug: {
      onSuccess = [ "hc-ping@${slug}.service" ];
    }) (lib.optionalAttrs (cfg.healthchecks.pingKeyFile != null) cfg.healthchecks.checks))
    ];

    systemd.timers.heartbeat = lib.mkIf (cfg.heartbeatUrlFile != null) {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "2min"; OnUnitActiveSec = cfg.heartbeatInterval; AccuracySec = "30s"; };
    };
  };
}
