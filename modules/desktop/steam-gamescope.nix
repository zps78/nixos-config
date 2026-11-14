# ../../modules/desktop/steam-gamescope.nix
#
# "Game mode" for the autologin session: Steam Big Picture inside
# gamescope, no desktop - like SteamOS. Built for krieger's seat0, where
# the unprivileged sessionUser ("steam") streams through Sunshine from an
# HDMI dummy plug.
#
# Why not just programs.steam.gamescopeSession on its own: its
# `steam-gamescope` script runs gamescope directly and never activates
# graphical-session.target, and Sunshine's user unit is
# WantedBy=graphical-session.target - so Sunshine would never start.
# This wraps it the same way niri-session wraps niri: a user service
# that BindsTo graphical-session.target, started (and waited on) from
# the greetd initial session, with a shutdown target afterwards. Sunshine
# keeps capturing the output via KMS regardless of which compositor
# draws it, and Moonlight input still arrives through uinput.
#
# Exiting Steam (or "Switch to Desktop", via the steamos-session-select
# shim below) ends the session and greetd falls back to its normal
# greeter on that seat.
{ config, lib, pkgs, ... }:

let
  cfg = config.myDesktop.steamGamescope;

  sessionScript = pkgs.writeShellScript "steam-gamescope-session" ''
    if systemctl --user -q is-active steam-gamescope.service; then
      echo "A Steam gamescope session is already running."
      exit 1
    fi
    systemctl --user reset-failed
    # Hand the login environment (XDG_SESSION_ID, XDG_SEAT, ...) to the
    # user manager - gamescope needs it to take the seat via logind.
    systemctl --user import-environment
    ${pkgs.dbus}/bin/dbus-update-activation-environment --all || true
    systemctl --user --wait start steam-gamescope.service
    systemctl --user start --job-mode=replace-irreversibly steam-gamescope-shutdown.target
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
  '';

  # Steam's "Switch to Desktop" calls steamos-session-select (a SteamOS
  # tool). There's no desktop on this seat, so just quit Steam, which
  # ends the session and returns to the greeter.
  sessionSelectShim = pkgs.writeShellScriptBin "steamos-session-select" ''
    exec steam -shutdown
  '';
in
{
  options.myDesktop.steamGamescope = {
    enable = lib.mkEnableOption "Steam Big Picture in gamescope as the autologin session (no desktop)";

    output = lib.mkOption {
      type = lib.types.str;
      example = "HDMI-A-1";
      description = "Connector gamescope should drive (the one Sunshine captures).";
    };
    width = lib.mkOption { type = lib.types.int; default = 1920; };
    height = lib.mkOption { type = lib.types.int; default = 1080; };
    refresh = lib.mkOption { type = lib.types.int; default = 60; };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.myFeatures.steam.enable;
        message = "myDesktop.steamGamescope needs myFeatures.steam.enable."; }
      { assertion = config.services.displayManager.autoLogin.enable;
        message = "myDesktop.steamGamescope replaces the autologin session; enable autoLogin."; }
    ];

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

    systemd.user.services.steam-gamescope = {
      description = "Steam Big Picture in gamescope (game mode session)";
      bindsTo = [ "graphical-session.target" ];
      before = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "/run/current-system/sw/bin/steam-gamescope";
        Restart = "no";
      };
    };

    systemd.user.targets.steam-gamescope-shutdown = {
      description = "Shutdown of the Steam gamescope session";
      conflicts = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      unitConfig = {
        DefaultDependencies = false;
        StopWhenUnneeded = true;
      };
    };

    # Replace the autologin session (niri-session, from
    # modules/desktop/niri.nix) - the user stays autoLogin.user.
    services.greetd.settings.initial_session.command = lib.mkForce "${sessionScript}";

    environment.systemPackages = [ sessionSelectShim ];
  };
}
