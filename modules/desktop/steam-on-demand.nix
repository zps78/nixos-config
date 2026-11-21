# ../../modules/desktop/steam-on-demand.nix
#
# Headless game streaming (kraken): no desktop, no greeter, no autologin.
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
# steam may start/stop/restart exactly these units and nothing else
# (polkit rule below) - it stays an unprivileged account.
#
# Optional second app, zen.enable: "Zen (VPN)" - the Zen browser full-screen
# in cage on the same dummy-plug output, inside a VPN-Confinement namespace
# (only the tunnel; kill switch). Same Sunshine/NVENC stream as Steam, so
# video plays at Moonlight quality. One app at a time (Sunshine refuses a
# second launch; the units conflict). Zen's disconnect grace is short
# (zen.idleStop, 30 s) - little time for anyone to resume into a browser.

{ config, lib, pkgs, ... }:

let
  cfg = config.myDesktop.steamOnDemand;
  user = config.myDesktop.sessionUser;
  uid = toString config.users.users.${user}.uid;

  unit = "steam-gamescope.service";
  idleTimer = "steam-gamescope-idle-stop.timer";
  zenUnit = "zen-vpn.service";
  zenTimer = "zen-vpn-idle-stop.timer";

  # Moonlight tile for "Zen (VPN)", 600x800 like Steam's: Zen's own vector
  # logo + wordmark (from the steam user's Zen package, so it follows Zen's
  # branding) on a dark gradient. omni.ja is a non-standard zip - unzip
  # reads it but complains, hence the checks instead of its exit code.
  zenPkg = config.home-manager.users.${user}.programs.zen-browser.package;
  zenBoxart = pkgs.runCommand "zen-vpn-boxart.png" {
    nativeBuildInputs = [ pkgs.unzip pkgs.librsvg pkgs.imagemagick ];
  } ''
    for f in about-logo about-wordmark; do
      unzip -p ${zenPkg}/lib/zen-bin-*/browser/omni.ja chrome/browser/content/branding/$f.svg > $f.svg 2>/dev/null || true
      [ -s $f.svg ] || { echo "$f.svg not found in Zen's omni.ja"; exit 1; }
    done
    rsvg-convert -w 480 about-logo.svg -o logo.png
    rsvg-convert -w 320 about-wordmark.svg -o word.png
    magick -size 600x800 gradient:'#2a2833'-'#121117' \
      \( logo.png \) -gravity center -geometry +0-70 -composite \
      \( word.png \) -gravity center -geometry +0+240 -composite \
      -depth 8 $out
  '';
  # Which app the current Sunshine session is (steam|zen) - lets the
  # disconnect/reconnect watcher treat them differently.
  stateFile = "/run/user/${uid}/sunshine-app";

  # cage runs this as its one client. Like gamescope: every output except
  # the dummy plug off (Sunshine captures "monitor 0" = the first plane with
  # a framebuffer, so a lit console monitor would be captured instead),
  # the dummy plug in the stream mode - a mode from its EDID list (NVIDIA
  # rejects a custom mode, "failed to apply configuration"). Logs the
  # before/after state to the journal. Then Zen full-screen.
  zenLauncher = pkgs.writeShellScript "zen-vpn-launch" ''
    r=${pkgs.wlr-randr}/bin/wlr-randr
    echo "== outputs at start"; $r
    for o in $($r --json | ${pkgs.jq}/bin/jq -r '.[].name'); do
      [ "$o" = ${cfg.output} ] || $r --output "$o" --off || echo "could not turn off $o"
    done
    $r --output ${cfg.output} --mode ${toString cfg.width}x${toString cfg.height}@${toString cfg.refresh} \
      || $r --output ${cfg.output} --mode ${toString cfg.width}x${toString cfg.height} \
      || echo "could not set ${toString cfg.width}x${toString cfg.height} on ${cfg.output}"
    echo "== outputs after"; $r
    exec /etc/profiles/per-user/${user}/bin/zen-beta
  '';

  # Called by Sunshine (as `user`) around each stream, and by the watcher.
  #   start steam|zen   prep-cmd "do" (app launch)
  #   stop  steam|zen   prep-cmd "undo" (app quit in Moonlight)
  #   resume            a client (re)connected
  #   stop-later        the last client disconnected
  ctl = pkgs.writeShellScript "steam-session-ctl" ''
    export PATH=${lib.makeBinPath [ pkgs.systemd pkgs.procps pkgs.coreutils ]}
    sc() { systemctl --no-ask-password "$@"; }
    app=$(cat ${stateFile} 2>/dev/null || echo steam)
    case "$1:''${2:-}" in
      start:steam)
        echo steam > ${stateFile}
        sc stop ${idleTimer} || true
        sc start ${unit}
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
      start:zen)
        echo zen > ${stateFile}
        sc stop ${zenTimer} || true
        sc start ${zenUnit}
        for _ in $(seq 60); do
          if pgrep -u ${user} -f "zen-beta|/zen " >/dev/null; then
            sleep 3
            exit 0
          fi
          sleep 1
        done
        ;;
      resume:*)
        # Sunshine does NOT re-run prep-cmd "do" on resume, so make sure the
        # session is (still/again) running. A resumed Zen is a fresh one.
        if [ "$app" = zen ]; then
          sc stop ${zenTimer} || true
          sc is-active -q ${zenUnit} || sc start ${zenUnit}
        else
          sc stop ${idleTimer} || true
          sc is-active -q ${unit} || sc start ${unit}
        fi
        ;;
      stop-later:*)
        # Last client gone: grace period, then the session stops (and with
        # it the Sunshine app - see appLife). Steam long (quick reconnects
        # keep the game), Zen short (privacy: little time to resume into it).
        if [ "$app" = zen ]; then sc restart ${zenTimer}; else sc restart ${idleTimer}; fi
        ;;
      stop:steam)
        sc stop ${idleTimer} || true
        sc stop ${unit}
        rm -f ${stateFile}
        ;;
      stop:zen)
        sc stop ${zenTimer} || true
        sc stop ${zenUnit}
        rm -f ${stateFile}
        ;;
      *)
        echo "usage: $0 start|stop steam|zen, or resume|stop-later" >&2
        exit 2
        ;;
    esac
  '';

  # The Sunshine app's "cmd": runs as long as the app's unit is active.
  # When it ends - Zen closed (Ctrl+Q), Steam exited, or the unit stopped
  # after a disconnect - Sunshine sees the app exit, ends the stream and
  # runs prep-cmd "undo". So closing the program is enough; no "Quit" in
  # Moonlight needed. (prep-cmd "do" has already started the unit.)
  appLife = pkgs.writeShellScript "sunshine-app-life" ''
    while ${pkgs.systemd}/bin/systemctl is-active -q "$1"; do ${pkgs.coreutils}/bin/sleep 2; done
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

    zen = {
      enable = lib.mkEnableOption "a second Sunshine app: the Zen browser in cage, inside a VPN namespace";
      idleStop = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "How long after a Moonlight disconnect Zen keeps running (short: it's a browser session).";
      };
      vpnNamespace = lib.mkOption {
        type = lib.types.str;
        default = "airvpn";
        description = "VPN-Confinement namespace Zen runs in (only the tunnel; kill switch).";
      };
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
      { assertion = !cfg.zen.enable || (config.vpnNamespaces ? ${cfg.zen.vpnNamespace});
        message = "myDesktop.steamOnDemand.zen: VPN namespace '${cfg.zen.vpnNamespace}' isn't defined (myServices.vpnTorrent)."; }
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
        # Always composite into the primary plane. Without this gamescope
        # scans Steam/games out directly on an overlay plane, leaving the
        # plane Sunshine's KMS capture reads empty ("Couldn't get drm fb
        # for plane [0]") - black stream with working audio. Known since
        # Sunshine 2026.906 (LizardByte/Sunshine#5839, bazzite#5828).
        # Costs one composite pass per frame - negligible on the 4060 Ti.
        "--force-composition"
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
      conflicts = [ "getty@tty${toString cfg.vt}.service" ] ++ lib.optional cfg.zen.enable zenUnit;

      # Services get a minimal PATH, but the steam-gamescope script (from
      # programs.steam.gamescopeSession) calls `gamescope` and `steam` by
      # name - without this it dies with "command not found" (exit 127).
      # Same order as a login shell: setcap/suid wrappers, the user's
      # home-manager profile, then system.
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

    ############################################################
    # Zen (VPN) - optional second app
    ############################################################

    # Hardware video decode for Zen on the NVIDIA GPU (VA-API -> NVDEC).
    hardware.graphics.extraPackages = lib.mkIf cfg.zen.enable [ pkgs.nvidia-vaapi-driver ];

    security.pam.services.zen-vpn.startSession = lib.mkIf cfg.zen.enable true;

    systemd.services.zen-vpn = lib.mkIf cfg.zen.enable {
      description = "Zen browser in cage, inside the ${cfg.zen.vpnNamespace} VPN namespace (on demand, for Sunshine)";
      after = [ "systemd-user-sessions.service" "systemd-logind.service" "user@${uid}.service" ];
      wants = [ "user@${uid}.service" ];
      conflicts = [ "getty@tty${toString cfg.vt}.service" unit ];

      path = [ "/run/wrappers" "/etc/profiles/per-user/${user}" "/run/current-system/sw" ];
      environment = {
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_CLASS = "user";
        XDG_RUNTIME_DIR = "/run/user/${uid}";                       # PipeWire (stream audio), session bus
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
        WLR_NO_HARDWARE_CURSORS = "1";                              # cursor drawn into the frame, so it's in the stream
        # Always composite into the primary plane - same reason as gamescope's
        # --force-composition: a full-screen Zen is otherwise scanned out
        # directly, the primary plane Sunshine's KMS capture reads stays empty
        # ("Couldn't get drm fb for plane [0]") and the stream is black.
        WLR_SCENE_DISABLE_DIRECT_SCANOUT = "1";
        MOZ_ENABLE_WAYLAND = "1";
        LIBVA_DRIVER_NAME = "nvidia";                               # VA-API video decode on the 4060 Ti
        NVD_BACKEND = "direct";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };

      serviceConfig = {
        User = user;
        PAMName = "zen-vpn";
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
        ExecStart = "${pkgs.cage}/bin/cage -d -s -- ${zenLauncher}";
        ExecStopPost = "+${pkgs.kbd}/bin/chvt 1";
        Restart = "no";
      };

      # Only the tunnel: DNS via the namespace's resolv.conf, host DNS cache
      # blocked, no route out if the tunnel is down.
      vpnConfinement = {
        enable = true;
        vpnNamespace = cfg.zen.vpnNamespace;
      };
    };

    systemd.timers.zen-vpn-idle-stop = lib.mkIf cfg.zen.enable {
      description = "Stop the Zen (VPN) session after a Moonlight disconnect";
      timerConfig = {
        OnActiveSec = cfg.zen.idleStop;
        AccuracySec = "1s";
        Unit = "zen-vpn-idle-stop.service";
      };
    };
    systemd.services.zen-vpn-idle-stop = lib.mkIf cfg.zen.enable {
      description = "Stop the Zen (VPN) session (idle after disconnect)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl stop ${zenUnit}";
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

    # steam may control exactly these units - nothing else.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}") {
          var unit = action.lookup("unit");
          var verb = action.lookup("verb");
          if ((unit == "${unit}" || unit == "${idleTimer}" || unit == "${zenUnit}" || unit == "${zenTimer}") &&
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
        # Capture monitor 0. Sunshine's KMS "monitor index" counts the
        # *planes that currently hold a framebuffer*, not connectors, and a
        # connector name like "HDMI-A-1" is translated to an index once, at
        # startup - while the console is still lit on every output (DP-2=0,
        # HDMI-A-1=1 on kraken). During a stream gamescope drives only
        # cfg.output and switches the other outputs off, so the one plane
        # with a framebuffer - Steam on the dummy plug - is index 0; index
        # 1 is empty and the stream is black ("Couldn't get drm fb for
        # plane [0]"). Read from sunshine 2026.914 src/platform/linux/kmsgrab.cpp.
        output_name = "0";
      } // lib.optionalAttrs (cfg.renderDevice != null) {
        adapter_name = cfg.renderDevice;
      };

      # Declarative app list (replaces the web UI's app editor).
      applications.apps = [
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          cmd = "${appLife} ${unit}";
          auto-detach = false;                     # a quickly ending cmd = app ended, not "detached"
          prep-cmd = [
            { do = "${ctl} start steam"; undo = "${ctl} stop steam"; }
          ];
        }
      ] ++ lib.optional cfg.zen.enable {
        name = "Zen (VPN)";
        image-path = "${zenBoxart}";
        cmd = "${appLife} ${zenUnit}";
        auto-detach = false;
        prep-cmd = [
          { do = "${ctl} start zen"; undo = "${ctl} stop zen"; }
        ];
      };
    };
  };
}
