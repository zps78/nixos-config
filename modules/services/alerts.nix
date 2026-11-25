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
  };

  config = lib.mkIf cfg.enable {
    age.secrets.ntfy-topic.file = ../../secrets/ntfy-topic.age;   # root 0400

    environment.systemPackages = [ ntfySend ];

    # ZED sources zed.rc as a shell script, so the topic is read from the
    # secret when ZED runs. VERBOSE: also report clean scrubs - a monthly
    # sign of life that alerts work.
    services.zfs.zed.settings = {
      ZED_NTFY_TOPIC = "$(cat ${topicFile})";
      ZED_NTFY_URL = cfg.server;
      ZED_NOTIFY_VERBOSE = lib.mkForce 1;
      ZED_NOTIFY_INTERVAL_SECS = 3600;   # same event class at most hourly
    };

    # smartd: our script instead of the NixOS notifications (wall to
    # logged-in terminals). Short self-test daily 02:00, long Sundays 04:00.
    services.smartd = {
      notifications.wall.enable = false;
      defaults.monitored = "-a -s (S/../.././02|L/../../7/04) -m <nomailer> -M exec ${smartdNotify}";
    };

    # "unit failed": an OnFailure hook on each listed unit.
    systemd.services = {
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
          curl -fsS -m 10 --retry 3 --retry-delay 5 -o /dev/null "$url"
        '';
      };
    } // lib.genAttrs cfg.failureUnits (_: {
      onFailure = [ "ntfy-failure@%n.service" ];
    });

    systemd.timers.heartbeat = lib.mkIf (cfg.heartbeatUrlFile != null) {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "2min"; OnUnitActiveSec = cfg.heartbeatInterval; AccuracySec = "30s"; };
    };
  };
}
