# ../../modules/desktop/stream-apps/default.nix
#
# Headless streaming apps (kraken): no desktop, no greeter, no autologin.
# Nothing graphical runs until Moonlight asks for it.
#
#   always on   the sessionUser ("steam") lingers, so its user manager runs
#               with no login: PipeWire (stream audio) + Sunshine (listening
#               for Moonlight). Sunshine captures via KMS (cap_sys_admin
#               wrapper), so it needs no compositor of its own.
#   on demand   a Moonlight app (Steam, Zen, Lutris - see the app modules)
#               starts its SYSTEM unit through Sunshine's prep-cmd: a real
#               logind session for steam on its own VT, the program on the
#               dummy-plug output.
#   afterwards  on disconnect (seen in Sunshine's log by a watcher - Sunshine
#               has no disconnect hook) the app's idle timer is (re)armed;
#               if nobody reconnects within its idleStop, the session is
#               stopped and the screen goes back to the text console. A
#               reconnect (Moonlight "resume") cancels it, or restarts the
#               session if it was already stopped. Quitting the app in
#               Moonlight (prep-cmd "undo") or closing the program ends it.
#
# This module is the core; each app registers itself in
# myDesktop.streamApps.apps (steam.nix, zen.nix, lutris.nix) and the core
# generates the session control script, the idle timers, the unit
# conflicts (one app at a time on the stream screen), steam's polkit rights
# for exactly these units, and Sunshine's app list. Shared helpers: lib.nix.
{ config, lib, pkgs, ... }:

let
  sa = import ./lib.nix { inherit config lib pkgs; };
  inherit (sa) cfg user uid stateFile;

  apps = lib.sort (a: b: a.order < b.order) (lib.attrValues cfg.apps);
  base = app: lib.removeSuffix ".service" app.unit;
  timerOf = app: "${base app}-idle-stop.timer";
  defaultApp = (lib.head apps).name;

  # Called by Sunshine (as `user`) around each stream, and by the watcher.
  #   start <app>   prep-cmd "do" (app launch)
  #   stop  <app>   prep-cmd "undo" (app quit in Moonlight)
  #   resume        a client (re)connected
  #   stop-later    the last client disconnected
  ctl = pkgs.writeShellScript "stream-session-ctl" ''
    export PATH=${lib.makeBinPath [ pkgs.systemd pkgs.procps pkgs.coreutils ]}
    sc() { systemctl --no-ask-password "$@"; }
    # Sunshine maps output_name to a plane index when the client connects,
    # counting the planes that hold a framebuffer at that moment. If the
    # console is still lit on another output (kraken: DP-2) the stream's
    # output gets index 1, the console then goes dark, and the stream stays
    # black ("Couldn't get drm fb for plane [0]") - seen 2026-11-23 on a
    # fresh Steam start. So hold the stream back until every other output
    # is off. Give up after 20 s (the stream starts anyway).
    others_off() {
      for c in /sys/class/drm/card*-*; do
        case "$c" in *-${cfg.output}) continue ;; esac
        [ "$(cat "$c/enabled" 2>/dev/null)" = enabled ] && return 1
      done
      return 0
    }
    wait_others_off() {
      for _ in $(seq 40); do others_off && return 0; sleep 0.5; done
      echo "other outputs still on after 20 s - starting anyway" >&2
    }
    ${cfg.ctlFunctions}
    app=$(cat ${stateFile} 2>/dev/null || echo ${defaultApp})
    case "$1:''${2:-}" in
    ${lib.concatMapStrings (a: ''
      start:${a.name})
        echo ${a.name} > ${stateFile}
        sc stop ${timerOf a} || true
        ${a.ctl.beforeStart}
        sc start ${a.unit}
        # Hold the stream back until the program is up, so Moonlight doesn't
        # open on the bare console; give up after ${toString a.waitSeconds} s.
        for _ in $(seq ${toString a.waitSeconds}); do
          if pgrep -u ${user} ${a.waitFor} >/dev/null; then
            sleep 3
            wait_others_off
            exit 0
          fi
          sleep 1
        done
        ;;
      stop:${a.name})
        sc stop ${timerOf a} || true
        ${a.ctl.beforeStop}
        sc stop ${a.unit}
        rm -f ${stateFile}
        ;;
    '') apps}
      resume:*)
        # Sunshine does NOT re-run prep-cmd "do" on resume, so make sure the
        # session is (still/again) running.
        case "$app" in
    ${lib.concatMapStrings (a: ''
          ${a.name})
            sc stop ${timerOf a} || true
            ${a.ctl.onResume}
            sc is-active -q ${a.unit} || sc start ${a.unit}
            ;;
    '') apps}
        esac
        ;;
      stop-later:*)
        # Last client gone: the app's grace period, then the session stops
        # (and with it the Sunshine app - see appLife).
        case "$app" in
    ${lib.concatMapStrings (a: ''
          ${a.name})
            ${if a.ctl.keepWhen != null
              then "if ${a.ctl.keepWhen}; then :; else sc restart ${timerOf a}; fi"
              else "sc restart ${timerOf a}"}
            ;;
    '') apps}
        esac
        ;;
      *)
        echo "usage: $0 start|stop ${lib.concatMapStringsSep "|" (a: a.name) apps}, or resume|stop-later" >&2
        exit 2
        ;;
    esac
  '';

  # The Sunshine app's "cmd": runs as long as the app's unit is active.
  # When it ends - program closed, or the unit stopped after a disconnect -
  # Sunshine sees the app exit, ends the stream and runs prep-cmd "undo".
  # So closing the program is enough; no "Quit" in Moonlight needed.
  # A unit that is restarting (Steam's "Restart") passes through
  # deactivating/inactive/activating; only "gone" for two checks in a row
  # (~4 s) counts as the app having ended.
  appLife = pkgs.writeShellScript "sunshine-app-life" ''
    gone=0
    while [ "$gone" -lt 2 ]; do
      case "$(${pkgs.systemd}/bin/systemctl is-active "$1")" in
        active|activating|deactivating|reloading|refreshing) gone=0 ;;
        *) gone=$((gone + 1)) ;;
      esac
      ${pkgs.coreutils}/bin/sleep 2
    done
  '';

  # Sunshine has no disconnect hook - prep-cmd "undo" only runs when the
  # app is quit, and a plain disconnect leaves the app "running" for a
  # later resume. So follow Sunshine's own log and react to its
  # CLIENT CONNECTED / CLIENT DISCONNECTED lines.
  watch = pkgs.writeShellScript "sunshine-session-watch" ''
    export PATH=${lib.makeBinPath [ pkgs.systemd pkgs.coreutils ]}
    journalctl --user -f -n 0 -o cat -t sunshine | while IFS= read -r line; do
      case "$line" in
        *"CLIENT DISCONNECTED"*) ${ctl} stop-later ;;
        *"CLIENT CONNECTED"*)    ${ctl} resume ;;
      esac
    done
  '';

  appType = lib.types.submodule ({ name, ... }: {
    options = {
      name = lib.mkOption { type = lib.types.str; default = name; readOnly = true; };
      title = lib.mkOption { type = lib.types.str; description = "App name in Moonlight."; };
      order = lib.mkOption { type = lib.types.int; description = "Position in Moonlight's app list."; };
      unit = lib.mkOption { type = lib.types.str; example = "steam-gamescope.service"; description = "The app's session unit (system service, defined by the app module)."; };
      tile = lib.mkOption { type = lib.types.package; description = "Moonlight tile (600x800 PNG)."; };
      label = lib.mkOption { type = lib.types.str; description = "Name in the idle timer's descriptions (\"Stop the <label> session ...\")."; };
      waitFor = lib.mkOption { type = lib.types.str; example = "-x steamwebhelper"; description = "pgrep arguments for \"the program is up\" (stream starts then)."; };
      waitSeconds = lib.mkOption { type = lib.types.int; default = 60; };
      idleStop = lib.mkOption { type = lib.types.str; description = "Grace period after a Moonlight disconnect."; };
      idleAccuracy = lib.mkOption { type = lib.types.str; default = "1s"; };
      # The idle stop service: by default just stops the unit.
      idleStopDescription = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      idleStopScript = lib.mkOption { type = lib.types.nullOr lib.types.lines; default = null; description = "Replaces the plain `systemctl stop <unit>`."; };
      idleStopServiceConfig = lib.mkOption { type = lib.types.attrs; default = { }; };
      # Hooks in the session control script (shell, run as the session user).
      ctl = {
        beforeStart = lib.mkOption { type = lib.types.lines; default = ""; };
        beforeStop = lib.mkOption { type = lib.types.lines; default = ""; };
        onResume = lib.mkOption { type = lib.types.lines; default = ""; };
        keepWhen = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Shell condition: on disconnect, don't arm the idle timer."; };
      };
    };
  });
in
{
  imports = [ ./steam.nix ./zen.nix ./lutris.nix ];

  options.myDesktop.streamApps = {
    enable = lib.mkEnableOption "headless streaming apps (Steam, Zen, Lutris ...), started by Sunshine on demand";

    output = lib.mkOption {
      type = lib.types.str;
      example = "HDMI-A-1";
      description = "Connector the apps drive (the dummy plug Sunshine captures).";
    };
    width = lib.mkOption { type = lib.types.int; default = 1920; };
    height = lib.mkOption { type = lib.types.int; default = 1080; };
    refresh = lib.mkOption { type = lib.types.int; default = 60; };

    vt = lib.mkOption {
      type = lib.types.ints.between 2 63;
      default = 7;
      description = "Virtual terminal the app sessions run on (tty1 keeps the console getty).";
    };

    renderDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/dri/by-path/pci-0000:0b:00.0-render";
      description = "GPU Sunshine encodes on (stable by-path name - matters once a second GPU is in the box).";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf appType;
      default = { };
      internal = true;
      description = "Registered apps (set by the app modules).";
    };

    ctlFunctions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      internal = true;
      description = "Shell functions app modules add to the session control script (for their ctl hooks).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.myServices.sunshine.enable;
        message = "myDesktop.streamApps needs myServices.sunshine.enable."; }
      { assertion = config.users.users.${user}.uid != null;
        message = "myDesktop.streamApps: pin users.users.${user}.uid (used for unit ordering and routing rules)."; }
      { assertion = apps != [ ];
        message = "myDesktop.streamApps: enable at least one app (steam/zen/lutris)."; }
    ];

    # Keep the user manager (PipeWire, Sunshine) running with nobody logged in.
    users.users.${user}.linger = true;

    systemd.services = lib.mkMerge (map (a: {
      # One app at a time on the stream screen: each session unit conflicts
      # with the console getty on its VT and with every other app.
      ${base a}.conflicts = [ "getty@tty${toString cfg.vt}.service" ]
        ++ map (o: o.unit) (lib.filter (o: o.name != a.name) apps);

      "${base a}-idle-stop" = {
        description = if a.idleStopDescription != null then a.idleStopDescription
                      else "Stop the ${a.label} session (idle after disconnect)";
        serviceConfig = { Type = "oneshot"; }
          // lib.optionalAttrs (a.idleStopScript == null) {
            ExecStart = "${pkgs.systemd}/bin/systemctl stop ${a.unit}";
          }
          // a.idleStopServiceConfig;
      } // lib.optionalAttrs (a.idleStopScript != null) {
        script = a.idleStopScript;
      };
    }) apps);

    # Disconnect grace period per app: armed by `stream-session-ctl stop-later`.
    systemd.timers = lib.mkMerge (map (a: {
      "${base a}-idle-stop" = {
        description = "Stop the ${a.label} session after a Moonlight disconnect";
        timerConfig = {
          OnActiveSec = a.idleStop;
          AccuracySec = a.idleAccuracy;
          Unit = "${base a}-idle-stop.service";
        };
      };
    }) apps);

    # steam may start/stop/restart exactly the app units and their idle
    # timers - nothing else (app modules may add narrower rules).
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}") {
          var unit = action.lookup("unit");
          var verb = action.lookup("verb");
          if ((${lib.concatMapStringsSep " ||\n               " (a: ''unit == "${a.unit}" || unit == "${timerOf a}"'') apps}) &&
              (verb == "start" || verb == "stop" || verb == "restart")) {
            return polkit.Result.YES;
          }
        }
      });
    '';

    ############################################################
    # Sunshine, headless
    ############################################################

    # Upstream hangs Sunshine off graphical-session.target, which never
    # exists here. Start it with the lingering user manager instead - for
    # the session user only (the admin's SSH logins would otherwise start one too).
    systemd.user.services.sunshine = {
      wantedBy = lib.mkForce [ "default.target" ];
      partOf = lib.mkForce [ ];
      wants = lib.mkForce [ "pipewire.service" ];
      after = lib.mkForce [ "pipewire.service" "pipewire-pulse.service" ];
      unitConfig.ConditionUser = user;
      # The lingering user manager starts Sunshine ~2 s before the NVIDIA
      # driver is up at boot (nvidia-drm, the GPU's render node and the
      # console framebuffer appear after it). Sunshine probes its encoder
      # once at startup and, if that fails ("Fatal: Unable to find display
      # or encoder during startup"), never retries - no streaming until it
      # is restarted. Seen 2026-11-20. Wait for the render node and fb0,
      # then let the driver settle; give up after 2 minutes and start
      # anyway (a restart can still fix it).
      serviceConfig.ExecStartPre = "${pkgs.writeShellScript "sunshine-wait-gpu" ''
        for _ in $(${pkgs.coreutils}/bin/seq 120); do
          [ -e ${if cfg.renderDevice != null then cfg.renderDevice else "/dev/dri/renderD128"} ] && [ -e /dev/fb0 ] && break
          ${pkgs.coreutils}/bin/sleep 1
        done
        ${pkgs.coreutils}/bin/sleep 5
      ''}";
      serviceConfig.TimeoutStartSec = "3min";
    };

    systemd.user.services.sunshine-session-watch = {
      description = "Stop/resume the stream app session on Moonlight disconnect/connect";
      wantedBy = [ "default.target" ];
      after = [ "sunshine.service" ];
      unitConfig.ConditionUser = user;
      serviceConfig = {
        ExecStart = "${watch}";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    services.sunshine = {
      settings = {
        sunshine_name = config.networking.hostName;
        capture = "kms";
        encoder = "nvenc";
        # Capture monitor 0. Sunshine's KMS "monitor index" counts the
        # *planes that currently hold a framebuffer*, not connectors. During
        # a stream only cfg.output is lit (the apps switch the other outputs
        # off), so its plane is index 0. (Sunshine is also patched to map a
        # screen to its first plane: modules/services/sunshine-primary-plane.patch.)
        output_name = "0";
      } // lib.optionalAttrs (cfg.renderDevice != null) {
        adapter_name = cfg.renderDevice;
      };

      # Declarative app list (replaces the web UI's app editor).
      applications.apps = map (a: {
        name = a.title;
        image-path = "${a.tile}";
        cmd = "${appLife} ${a.unit}";
        auto-detach = false;                       # a quickly ending cmd = app ended, not "detached"
        prep-cmd = [
          { do = "${ctl} start ${a.name}"; undo = "${ctl} stop ${a.name}"; }
        ];
      }) apps;
    };
  };
}
