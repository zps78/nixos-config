# ../../modules/desktop/stream-apps/steam.nix
#
# Stream app "Steam Big Picture": Steam in gamescope on the dummy plug
# (system unit steam-gamescope.service). Steam's power menu acts on the
# session only, like a VM:
#   Turn off     -> session stopped (stream ends), kraken stays on
#   Restart      -> session restarted
#   Suspend      -> session frozen (systemctl freeze) and kept without a
#                   disconnect countdown until the next reconnect thaws it;
#                   a cap timer ends a forgotten one (suspendCap)
#   Switch to Desktop -> there is none: Steam quits, the session ends
{ config, lib, pkgs, ... }:

let
  sa = import ./lib.nix { inherit config lib pkgs; };
  inherit (sa) user uid;
  scfg = config.myDesktop.streamApps;
  cfg = scfg.steam;

  unit = "steam-gamescope.service";
  idleTimer = "steam-gamescope-idle-stop.timer";
  capTimer = "steam-gamescope-suspend-cap.timer";
  suspendFlag = "/run/user/${uid}/steam-suspended";

  # Steam logo from Simple Icons, in Steam blue (2026-11-23, the user liked
  # Zen's tile better than Sunshine's stock steam.png).
  tile = sa.mkTile {
    name = "steam";
    label = "Steam";
    logoSvg = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/npm/simple-icons@11.0.0/icons/steam.svg";
      hash = "sha256-Xu+PMRBrgZVu2QhJC8+Mc6vkdqpYu5BBrN9wsNQuvK4=";
    };
    fill = "#1A9FFF";
  };

  # Steam asks logind to power off/reboot/suspend the whole machine
  # (2026-11-24: it did shut kraken down). polkit (below) refuses those
  # requests for the steam user; this root watcher sees them on the system
  # bus and does the session version.
  powerIntercept = pkgs.writeShellScript "steam-power-intercept" ''
    export PATH=${lib.makeBinPath [ pkgs.dbus pkgs.systemd pkgs.coreutils pkgs.gnugrep ]}
    uid=$(id -u ${user})
    dbus-monitor --system \
      "type='method_call',destination='org.freedesktop.login1',interface='org.freedesktop.login1.Manager'" |
    while read -r line; do
      case "$line" in
        "method call"*) ;;
        *) continue ;;
      esac
      member=''${line##*member=}
      case "$member" in
        PowerOff|PowerOffWithFlags|Halt|HaltWithFlags) verb=stop ;;
        Reboot|RebootWithFlags|SoftReboot*) verb=restart ;;
        Suspend|SuspendWithFlags|Hibernate|HibernateWithFlags|HybridSleep*|SuspendThenHibernate*) verb=suspend ;;
        *) continue ;;
      esac
      sender=$(echo "$line" | grep -oE 'sender=[^ ]+' | cut -d= -f2)
      suid=$(busctl --system call org.freedesktop.DBus /org/freedesktop/DBus \
               org.freedesktop.DBus GetConnectionUnixUser s "$sender" 2>/dev/null | cut -d' ' -f2)
      [ "$suid" = "$uid" ] || continue
      echo "steam asked logind for $member -> $verb ${unit}"
      case "$verb" in
        suspend)
          # Freeze the whole session (Steam, gamescope, the game) and keep
          # it: no disconnect countdown (the session control checks the
          # flag), only the cap timer. The next reconnect thaws it.
          systemctl is-active -q ${unit} || continue
          systemctl stop ${idleTimer} || true
          touch ${suspendFlag} && chown ${user}: ${suspendFlag}
          systemctl freeze ${unit} && systemctl start ${capTimer} \
            || { echo "freeze failed - leaving the session running"; rm -f ${suspendFlag}; }
          ;;
        *)
          rm -f ${suspendFlag}; systemctl stop ${capTimer} || true
          systemctl "$verb" --no-block ${unit}
          ;;
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
  options.myDesktop.streamApps.steam = {
    enable = lib.mkEnableOption "the Steam Big Picture stream app (gamescope)";

    idleStop = lib.mkOption {
      type = lib.types.str;
      default = "3min";
      description = "How long after a Moonlight disconnect Steam/gamescope keep running (quick reconnects don't restart Steam).";
    };

    suspendCap = lib.mkOption {
      type = lib.types.str;
      default = "8h";
      description = ''
        Steam's "Suspend" freezes the session and keeps it (no disconnect
        countdown) until the next Moonlight reconnect thaws it. After this
        long suspended, the session is ended anyway.
      '';
    };
  };

  config = lib.mkIf (scfg.enable && cfg.enable) {
    assertions = [
      { assertion = config.myFeatures.steam.enable;
        message = "myDesktop.streamApps.steam needs myFeatures.steam.enable."; }
    ];

    myDesktop.streamApps.apps.steam = {
      title = "Steam Big Picture";
      order = 10;
      inherit unit tile;
      label = "Steam gamescope";
      # Steam's UI is up. First launch self-updates Steam: wait up to 2 min.
      waitFor = "-x steamwebhelper";
      waitSeconds = 120;
      inherit (cfg) idleStop;
      idleAccuracy = "5s";
      # systemd refuses to stop a frozen unit ("Cannot perform operation
      # on frozen unit") - thaw first, in case a suspended one ends here.
      idleStopServiceConfig = {
        ExecStartPre = "-${pkgs.systemd}/bin/systemctl thaw ${unit}";
        ExecStartPost = "${pkgs.coreutils}/bin/rm -f ${suspendFlag}";
      };
      ctl = {
        beforeStart = "unsuspend";
        beforeStop = "unsuspend                                  # thaw first, so the stop can run";
        onResume = "unsuspend                                    # Steam \"Suspend\": thaw, game continues";
        keepWhen = "[ -e ${suspendFlag} ]";                    # suspended: no countdown (only the cap timer)
      };
    };

    # Undo Steam's "Suspend" (steam-power-intercept froze the session).
    myDesktop.streamApps.ctlFunctions = ''
      unsuspend() {
        [ -e ${suspendFlag} ] || return 0
        sc thaw ${unit} || true
        sc stop ${capTimer} || true
        rm -f ${suspendFlag}
      }
    '';

    programs.steam.gamescopeSession = {
      enable = true;
      # Output resolution/refresh (-W/-H/-r) and the game render size
      # (-w/-h) both match the dummy plug's mode, so nothing is scaled.
      args = [
        # Always composite into the primary plane. Without this gamescope
        # scans Steam/games out directly on an overlay plane, leaving the
        # plane Sunshine's KMS capture reads empty ("Couldn't get drm fb
        # for plane [0]") - black stream with working audio. Known since
        # Sunshine 2026.906 (LizardByte/Sunshine#5839, bazzite#5828).
        # Costs one composite pass per frame - negligible on the 4060 Ti.
        "--force-composition"
        # (Even so, a logged-in Steam's overlay layer gets its own overlay
        # plane on NVIDIA - --disable-layers doesn't prevent it. Sunshine is
        # patched to capture the primary plane instead: see
        # modules/services/sunshine-primary-plane.patch.)
        "--prefer-output" scfg.output
        "-W" (toString scfg.width) "-H" (toString scfg.height)
        "-w" (toString scfg.width) "-h" (toString scfg.height)
        "-r" (toString scfg.refresh)
      ];
    };

    environment.systemPackages = [ sessionSelectShim ];

    security.pam.services.steam-gamescope.startSession = true;

    systemd.services.steam-gamescope = sa.sessionUnit {
      description = "Steam Big Picture in gamescope (on demand, for Sunshine)";
      pamName = "steam-gamescope";
      # The steam-gamescope script (programs.steam.gamescopeSession) calls
      # `gamescope` and `steam` by name - the session PATH has them.
      execStart = "/run/current-system/sw/bin/steam-gamescope";
    } // {
      # A rebuild doesn't restart a running session (it may be a game in
      # progress, or frozen by Steam's "Suspend" - systemd can't stop a
      # frozen unit). The new config applies at the next session start.
      restartIfChanged = false;
    };

    # Shutdown of kraken with a suspended (frozen) Steam session: systemd
    # can't stop a frozen unit. This helper is ordered after the session, so
    # it's stopped before it and thaws it on the way down.
    systemd.services.steam-gamescope-thaw-guard = {
      description = "Thaw a suspended Steam session before it is stopped at shutdown";
      wantedBy = [ "multi-user.target" ];
      after = [ unit ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = "-${pkgs.systemd}/bin/systemctl thaw ${unit}";
      };
    };

    # Cap for a suspended (frozen) Steam session: started by
    # steam-power-intercept on "Suspend", stopped by the reconnect that
    # thaws it. Ends a forgotten one after suspendCap.
    systemd.timers.steam-gamescope-suspend-cap = {
      description = "End a suspended Steam session after ${cfg.suspendCap}";
      timerConfig = {
        OnActiveSec = cfg.suspendCap;
        AccuracySec = "1min";
        Unit = "steam-gamescope-suspend-cap.service";
      };
    };
    systemd.services.steam-gamescope-suspend-cap = {
      description = "End the suspended Steam session (cap reached)";
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.systemd}/bin/systemctl thaw ${unit} || true
        ${pkgs.systemd}/bin/systemctl stop ${unit}
        rm -f ${suspendFlag}
      '';
    };

    security.polkit.extraConfig = ''
      // resume from Steam's "Suspend": steam may thaw its session and drop the cap
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}") {
          var unit = action.lookup("unit");
          var verb = action.lookup("verb");
          if ((unit == "${unit}" && verb == "thaw") ||
              (unit == "${capTimer}" && verb == "stop")) {
            return polkit.Result.YES;
          }
        }
      });
      // No machine power for steam (Steam's power menu would turn off or
      // reboot the whole NAS). AUTH_ADMIN, not NO: logind's CanPowerOff then
      // says "challenge", so Steam still offers the menu entries; there's no
      // auth agent in the session, so the request fails and
      // steam-power-intercept turns it into a session stop/restart/freeze.
      polkit.addRule(function(action, subject) {
        if (subject.user == "${user}" &&
            /^org\.freedesktop\.login1\.(power-off|reboot|halt|suspend|hibernate|soft-reboot)/.test(action.id)) {
          return polkit.Result.AUTH_ADMIN;
        }
      });
    '';

    systemd.services.steam-power-intercept = {
      description = "Turn Steam's power-off/reboot into a Steam session stop/restart";
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      serviceConfig = {
        ExecStart = powerIntercept;
        Restart = "always";
        RestartSec = "2s";
      };
    };
  };
}
