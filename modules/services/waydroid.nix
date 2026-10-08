# ../../modules/services/waydroid.nix
#
# Waydroid itself is just virtualisation.waydroid.enable. Two imperative,
# one-time steps sit on top of that, neither of which a Nix derivation can
# bake in ahead of time (one downloads a multi-GB OTA image, the other
# patches files into the live Android overlay at runtime), so both are
# wired up as idempotent, marker-guarded automation instead of being left
# as manual steps:
#
#   1. `waydroid init` - picks the system image (vanilla/FOSS/GAPPS) and
#      downloads it. Runs as a root-level oneshot service pulled in by
#      upstream's waydroid-container.service, guarded by ConditionPathExists
#      so it only ever runs once per host.
#   2. waydroid_script extras (microG by default) - patches them into the
#      already-running container. Needs an actual Waydroid *session* (not
#      just the container), so it's a user-level service, with a narrowly
#      scoped passwordless sudo rule for exactly the installer script (not
#      for waydroid_script in general).
{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.myServices.waydroid;

  waydroidScriptPkg = inputs.waydroid-script.packages.${pkgs.system}.default;

  # Dropped by `waydroid init` itself inside the (root-owned) data dir as
  # part of unpacking the system image - present iff init has already
  # completed, regardless of which system type was chosen. Used below as
  # the idempotency check for both the init service (skip if present) and
  # nothing else needs it.
  initMarker = "/var/lib/waydroid/waydroid_base.prop";

  markerDir = "/var/lib/waydroid-extras";

  # Root-owned: for each configured extra not yet marked done, run
  # waydroid_script's installer once and drop a marker so it's never
  # re-run on subsequent boots/logins (the container's overlay persists
  # across reboots, so re-installing would be redundant at best).
  installExtrasScript = pkgs.writeShellScript "waydroid-install-extras" ''
    set -e
    mkdir -p ${markerDir}
    ${lib.concatMapStringsSep "\n" (extra: ''
      if [ ! -e "${markerDir}/${extra}.done" ]; then
        echo "waydroid-extras: installing ${extra}..."
        if ${waydroidScriptPkg}/bin/waydroid_script install ${extra}; then
          touch "${markerDir}/${extra}.done"
        else
          echo "waydroid-extras: ${extra} failed, will retry next run" >&2
        fi
      fi
    '') cfg.extras}
  '';
in
{
  options.myServices.waydroid = {
    enable = lib.mkEnableOption "Waydroid";

    systemType = lib.mkOption {
      type = lib.types.enum [ "VANILLA" "FOSS" "GAPPS" ];
      default = "VANILLA";
      description = ''
        System image `waydroid init` downloads on first run (passed as
        `-s`). VANILLA matches upstream's own default and is the right
        choice here - GAPPS would just be redundant with the microG extra
        above. Only takes effect before the one-time init has happened;
        changing it afterwards does nothing unless the init marker
        (${initMarker}) is removed first.
      '';
    };

    extras = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "gapps" "magisk" "libndk" "libhoudini" "nodataperm" "smartdock" "microg" "mitm" "widevine"
      ]);
      default = [ "microg" "widevine" ];
      description = ''
        waydroid_script extras (github:casualsnek/waydroid_script) to
        auto-install the first time a Waydroid session is detected running.
        Each one only ever runs once per host (tracked via marker files in
        ${markerDir}); add to this list later to pick up new extras the same
        way.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;

    # Root-level and system-wide (not per-user), since `waydroid init` only
    # needs root + network, not a logged-in session. Pulled in as a
    # dependency of upstream's waydroid-container.service (itself
    # wantedBy multi-user.target) and ordered before it, so the container
    # never tries to start against a not-yet-downloaded image; guarded by
    # ConditionPathExists so it's a no-op on every boot after the first.
    systemd.services.waydroid-init = {
      description = "Initialize Waydroid system image (one-time)";
      before = [ "waydroid-container.service" ];
      wantedBy = [ "waydroid-container.service" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig = {
        ConditionPathExists = "!${initMarker}";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.virtualisation.waydroid.package}/bin/waydroid init -s ${cfg.systemType}";
      };
    };

    security.sudo.extraRules = lib.mkIf (cfg.extras != [ ]) [
      {
        users = [ config.myDesktop.primaryUser ];
        commands = [
          {
            command = "${installExtrasScript}";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # User-level (not system-level) because it has to wait for a Waydroid
    # *session* - which only exists once someone's logged into the
    # graphical session and either opened a Waydroid app or run
    # `waydroid session start` themselves - not merely for
    # waydroid-container.service, which is up well before that and tells
    # you nothing about session state. Polls rather than hooking a
    # specific event, since nothing emits a clean "session started"
    # signal to wait on; gives up after 2 minutes so a host where nobody
    # ever starts a session doesn't spin forever every login.
    systemd.user.services.waydroid-extras = lib.mkIf (cfg.extras != [ ]) {
      description = "Install configured Waydroid extras (microG, etc.) once a session is up";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "waydroid-extras-wait-and-install" ''
          for i in $(seq 1 24); do
            if ${pkgs.waydroid}/bin/waydroid status 2>/dev/null | grep -qE "^Session:[[:space:]]*RUNNING"; then
              exec /run/wrappers/bin/sudo ${installExtrasScript}
            fi
            sleep 5
          done
          echo "waydroid-extras: no Waydroid session detected after 2 minutes, giving up for this login" >&2
        '';
      };
    };
  };
}
