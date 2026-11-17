# ../../modules/desktop/steam-on-demand.nix
#
# Headless game streaming (karma): no desktop, no greeter, no autologin.
# Nothing graphical runs until Moonlight asks for it.
#
#   always on   the sessionUser ("steam") lingers, so its user manager runs
#               with no login: PipeWire (stream audio) + Sunshine (listening
#               for Moonlight). Sunshine captures via KMS (cap_sys_admin
#               wrapper), so it needs no compositor of its own.
#   on demand   Moonlight -> "Steam Big Picture": Sunshine's prep-cmd starts
#               the SYSTEM unit steam-gamescope.service, which opens a real
#               logind session for steam on its own VT (gamescope needs an
#               active seat0 session to become DRM master) and runs Steam
#               Big Picture in gamescope on the dummy-plug output.
#   afterwards  on disconnect (seen in Sunshine's log by a watcher - Sunshine
#               has no disconnect hook) a timer is (re)armed; if nobody
#               reconnects within idleStop, gamescope + Steam are stopped
#               and the screen goes back to the text console. A reconnect
#               (Moonlight "resume") cancels it, or restarts the session if
#               it was already stopped. Quitting the app in Moonlight
#               (prep-cmd "undo") or Exit in Steam ends it at once.
#
# steam may start/stop/restart exactly these two units and nothing else
# (polkit rule below) - it stays an unprivileged account.
#
# Contrast with myDesktop.steamGamescope (krieger): that one makes Steam
# the greetd autologin session. Don't enable both.
{ config, lib, pkgs, ... }:

let
  cfg = config.myDesktop.steamOnDemand;
  user = config.myDesktop.sessionUser;
  uid = toString config.users.users.${user}.uid;

  unit = "steam-gamescope.service";
  idleTimer = "steam-gamescope-idle-stop.timer";

  # Called by Sunshine (as `user`) around each stream.
  ctl = pkgs.writeShellScript "steam-session-ctl" ''
    export PATH=${lib.makeBinPath [ pkgs.systemd pkgs.procps pkgs.coreutils ]}
    case "$1" in
      start)
        # App launch (Sunshine prep-cmd "do").
        systemctl --no-ask-password stop ${idleTimer} || true
        systemctl --no-ask-password start ${unit}
        # Hold the stream back until Steam's UI is up, so Moonlight doesn't
        # open on the bare console. Give up waiting after 2 minutes (first
        # launch self-updates Steam; the stream then starts anyway).
        for _ in $(seq 120); do
          if pgrep -u ${user} -x steamwebhelper >/dev/null; then
            sleep 3
            exit 0
          fi
          sleep 1
        done
        ;;
      resume)
        # A client (re)connected - Sunshine does NOT re-run prep-cmd "do"
        # on resume, so make sure the session is (still/again) running.
        systemctl --no-ask-password stop ${idleTimer} || true
        systemctl --no-ask-password is-active -q ${unit} \
          || systemctl --no-ask-password start ${unit}
        ;;
      stop-later)
        # Last client disconnected: grace period before stopping.
        systemctl --no-ask-password restart ${idleTimer}
        ;;
      stop)
        # App quit in Moonlight (prep-cmd "undo"): stop now.
        systemctl --no-ask-password stop ${idleTimer} || true
        systemctl --no-ask-password stop ${unit}
        ;;
      *)
        echo "usage: $0 start|resume|stop-later|stop" >&2
        exit 2
        ;;
    esac
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

  # Steam's "Switch to Desktop" calls steamos-session-select (a SteamOS
  # tool). There is no desktop here: just quit Steam, which ends the session.
  sessionSelectShim = pkgs.writeShellScriptBin "steamos-session-select" ''
    exec steam -shutdown
  '';
in
{
  options.myDesktop.steamOnDemand = {
    enable = lib.mkEnableOption "headless Steam Big Picture in gamescope, started by Sunshine on demand";

    output = lib.mkOption {
      type = lib.types.str;
      example = "HDMI-A-1";
      description = "Connector gamescope drives (the dummy plug Sunshine captures).";
    };
    width = lib.mkOption { type = lib.types.int; default = 1920; };
    height = lib.mkOption { type = lib.types.int; default = 1080; };
    refresh = lib.mkOption { type = lib.types.int; default = 60; };

    vt = lib.mkOption {
      type = lib.types.ints.between 2 63;
      default = 7;
      description = "Virtual terminal the gaming session runs on (tty1 keeps the console getty).";
    };

    idleStop = lib.mkOption {
      type = lib.types.str;
      default = "3min";
      description = "How long after a Moonlight disconnect Steam/gamescope keep running (quick reconnects don't restart Steam).";
    };

    renderDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/dri/by-path/pci-0000:0b:00.0-render";
      description = "GPU Sunshine encodes on (stable by-path name - matters once a second GPU is in the box).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.myFeatures.steam.enable;
        message = "myDesktop.steamOnDemand needs myFeatures.steam.enable."; }
      { assertion = config.myServices.sunshine.enable;
        message = "myDesktop.steamOnDemand needs myServices.sunshine.enable."; }
      { assertion = !config.myDesktop.steamGamescope.enable;
        message = "myDesktop.steamOnDemand and myDesktop.steamGamescope are alternatives - enable one."; }
      { assertion = config.users.users.${user}.uid != null;
        message = "myDesktop.steamOnDemand: pin users.users.${user}.uid (used for unit ordering and routing rules)."; }
    ];

    # Keep the user manager (PipeWire, Sunshine) running with nobody logged in.
    users.users.${user}.linger = true;

    ############################################################
    # Steam in gamescope
    ############################################################

    programs.steam.gamescopeSession = {
      enable = true;
      # Output resolution/refresh (-W/-H/-r) and the game render size
      # (-w/-h) both match the dummy plug's mode, so nothing is scaled.
      args = [
        "--prefer-output" cfg.output
        "-W" (toString cfg.width) "-H" (toString cfg.height)
        "-w" (toString cfg.width) "-h" (toString cfg.height)
        "-r" (toString cfg.refresh)
      ];
    };

    environment.systemPackages = [ sessionSelectShim ];

    # A real login session (pam_systemd) on its own VT - same pattern as
    # NixOS's cage kiosk module. chvt makes the VT the foreground one, so
    # logind marks the session active and gamescope can take DRM master;
    # on exit the screen goes back to the tty1 console.
    security.pam.services.steam-gamescope.startSession = true;

    systemd.services.steam-gamescope = {
      description = "Steam Big Picture in gamescope (on demand, for Sunshine)";
      after = [ "systemd-user-sessions.service" "systemd-logind.service" "user@${uid}.service" ];
      wants = [ "user@${uid}.service" ];
      conflicts = [ "getty@tty${toString cfg.vt}.service" ];

      # See modules/desktop/steam-gamescope.nix: the steam-gamescope script
      # calls gamescope/steam by name.
      path = [ "/run/wrappers" "/etc/profiles/per-user/${user}" "/run/current-system/sw" ];
      environment = {
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_CLASS = "user";
      };

      serviceConfig = {
        User = user;
        PAMName = "steam-gamescope";
        WorkingDirectory = "~";

        TTYPath = "/dev/tty${toString cfg.vt}";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";
        UtmpIdentifier = "tty${toString cfg.vt}";
        UtmpMode = "user";

        ExecStartPre = "+${pkgs.kbd}/bin/chvt ${toString cfg.vt}";
        ExecStart = "/run/current-system/sw/bin/steam-gamescope";
        ExecStopPost = "+${pkgs.kbd}/bin/chvt 1";
        Restart = "no";
      };
    };

    # Disconnect grace period: armed by `steam-session-ctl stop-later`.
    systemd.timers.steam-gamescope-idle-stop = {
      description = "Stop the Steam gamescope session after a Moonlight disconnect";
      timerConfig = {
        OnActiveSec = cfg.idleStop;
        AccuracySec = "5s";
        Unit = "steam-gamescope-idle-stop.service";
      };
    };
    systemd.services.steam-gamescope-idle-stop = {
      description = "Stop the Steam gamescope session (idle after disconnect)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl stop ${unit}";
      };
    };

    # steam may control exactly these two units - nothing else.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}") {
          var unit = action.lookup("unit");
          var verb = action.lookup("verb");
          if ((unit == "${unit}" || unit == "${idleTimer}") &&
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
    # the session user only (dh's SSH logins would otherwise start one too).
    systemd.user.services.sunshine = {
      wantedBy = lib.mkForce [ "default.target" ];
      partOf = lib.mkForce [ ];
      wants = lib.mkForce [ "pipewire.service" ];
      after = lib.mkForce [ "pipewire.service" "pipewire-pulse.service" ];
      unitConfig.ConditionUser = user;
    };

    systemd.user.services.sunshine-session-watch = {
      description = "Stop/resume the Steam gamescope session on Moonlight disconnect/connect";
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
        # Capture the dummy plug gamescope draws on - not the first
        # connected output (DP-2, the console monitor, on karma).
        output_name = cfg.output;
      } // lib.optionalAttrs (cfg.renderDevice != null) {
        adapter_name = cfg.renderDevice;
      };

      # Declarative app list (replaces the web UI's app editor).
      applications.apps = [
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          prep-cmd = [
            { do = "${ctl} start"; undo = "${ctl} stop"; }
          ];
        }
      ];
    };
  };
}
