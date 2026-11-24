# ../../modules/desktop/stream-apps/lutris.nix
#
# Stream app "Lutris": installing games from installers (DODI/FitGirl
# Setup.exe etc.) with a real GUI over the stream, on the normal network.
# Runners/prefixes in steam's home; install games to /mnt/games/nonsteam/
# <Game> (Z:\mnt\games\nonsteam\... in Wine). Games installed there can be
# added to Steam as non-Steam games, or played from Lutris itself.
{ config, lib, pkgs, ... }:

let
  sa = import ./lib.nix { inherit config lib pkgs; };
  inherit (sa) user uid;
  scfg = config.myDesktop.streamApps;
  cfg = scfg.lutris;

  unit = "lutris-session.service";
  timer = "lutris-session-idle-stop.timer";
  launcher = sa.kioskLauncher "lutris-launch" "${pkgs.lutris}/bin/lutris";

  # Lutris runs in labwc, not cage: cage is a kiosk (one full-screen app)
  # and hid Lutris's Preferences dialog behind the main window (2026-11-24);
  # Wine installers open extra windows too. labwc stacks them normally,
  # with title bars to move them. Main window maximized (first window
  # titled "Lutris" only), no panel or desktop. -S ends labwc with Lutris.
  labwcConfig = pkgs.writeTextDir "rc.xml" ''
    <?xml version="1.0"?>
    <labwc_config>
      <core><decoration>server</decoration></core>
      <windowRules>
        <windowRule identifier="net.lutris.Lutris" title="Lutris" matchOnce="true">
          <action name="Maximize"/>
        </windowRule>
      </windowRules>
    </labwc_config>
  '';

  # Lutris's own logo (from the package, follows its branding). The SVG has
  # a 5/280 margin, so 290 px -> 280 px visible, placed 5 px up-left.
  tile = sa.mkTile {
    name = "lutris";
    label = "Lutris";
    logoSvg = "${pkgs.lutris}/share/icons/hicolor/scalable/apps/net.lutris.Lutris.svg";
    logoSize = 290;
    logoPos = "+155+185";
  };
in
{
  options.myDesktop.streamApps.lutris = {
    enable = lib.mkEnableOption "the Lutris stream app: Lutris in labwc, to install games from installers with a GUI";
    idleStop = lib.mkOption {
      type = lib.types.str;
      default = "2h";
      description = ''
        How long after a Moonlight disconnect Lutris keeps running (long:
        repacks can take an hour to install). Even then it's only stopped
        when no Wine process (an installer) is running - otherwise it
        waits another round.
      '';
    };
  };

  config = lib.mkIf (scfg.enable && cfg.enable) {
    myDesktop.streamApps.apps.lutris = {
      title = "Lutris";
      order = 30;
      inherit unit tile;
      label = "Lutris";
      waitFor = ''-f "lutris"'';
      inherit (cfg) idleStop;
      idleAccuracy = "10s";
      idleStopDescription = "Stop the Lutris session (idle after disconnect), unless an installer still runs";
      idleStopScript = ''
        # wineserver lives as long as anything runs in a Wine prefix - an
        # installer still unpacking: don't cut it off, check again later.
        if ${pkgs.procps}/bin/pgrep -u ${user} -x wineserver >/dev/null; then
          echo "Wine still busy (installer?) - Lutris stays, next check in ${cfg.idleStop}"
          ${pkgs.systemd}/bin/systemctl restart ${timer}
          exit 0
        fi
        ${pkgs.systemd}/bin/systemctl stop ${unit}
      '';
    };

    security.pam.services.lutris-session.startSession = true;

    systemd.services.lutris-session = sa.sessionUnit {
      description = "Lutris in labwc (on demand, for Sunshine)";
      pamName = "lutris-session";
      # labwc, not cage (see labwcConfig): dialogs and installer windows
      # stack on top instead of hiding behind Lutris.
      execStart = "${pkgs.labwc}/bin/labwc -C ${labwcConfig} -S ${launcher}";
      environment = {
        XDG_RUNTIME_DIR = "/run/user/${uid}";                       # PipeWire (stream audio), session bus
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
        WLR_NO_HARDWARE_CURSORS = "1";                              # cursor drawn into the frame, so it's in the stream
        WLR_SCENE_DISABLE_DIRECT_SCANOUT = "1";                     # same reason as Zen: keep the primary plane filled
      };
      serviceConfig = {
        # No capabilities at all in this session: Lutris is a bubblewrap
        # FHS env, and bwrap dies with "Unexpected capabilities but not
        # setuid" if its process holds any (the steam user's sessions
        # inherit CAP_WAKE_ALARM from its user manager; seen 2026-11-24,
        # Lutris closed 2 s after start). labwc/Lutris/Wine need none.
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    } // {
      # Never cut off a running install with a rebuild.
      restartIfChanged = false;
    };
  };
}
