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
#      just the container), so detecting "time to run" has to live in a
#      user-level service - but the actual work runs as a genuine
#      system-level service (waydroid-extras-install, root, PID1-managed),
#      triggered on demand via a narrowly scoped passwordless sudo rule for
#      exactly `systemctl start --wait` on that one unit. This split isn't
#      just tidiness: an earlier version had the user service `sudo exec`
#      the installer script directly, and that broke in two different ways
#      under real testing (a stray root-owned process the user systemd
#      instance couldn't kill from its cgroup - "Operation not permitted" -
#      on one run, and a silent no-op with zero markers written despite a
#      reported clean exit on another), both consistent with the same root
#      cause: a process escalated to root via sudo sitting in a cgroup
#      that's owned and tracked by the *user's* systemd instance, which
#      structurally can't manage it. Running the work as a real system
#      service under root's own systemd instance from the start removes
#      that mismatch entirely.
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

    # Real system-level service doing the actual extras install - root,
    # under PID1's own systemd instance, so its cgroup/process tracking is
    # self-consistent (see the top-of-file comment for why that matters).
    # Never wantedBy anything - it only ever runs when explicitly started
    # (by the user-level waydroid-extras service below, or manually), since
    # it needs an actual Waydroid session, not just the container. No
    # RemainAfterExit: it has to be re-runnable (each run just re-checks
    # the per-extra markers) so that adding a new extra to cfg.extras later
    # and re-triggering it picks the new one up instead of being short-
    # circuited by "already ran once this boot".
    systemd.services.waydroid-extras-install = lib.mkIf (cfg.extras != [ ]) {
      description = "Install configured Waydroid extras (microG, etc.)";
      # waydroid_script shells out to plain `waydroid` (e.g. to restart the
      # container after copying an extra's files in) without a full path -
      # needs this or every extra "installs" its files fine and then fails
      # right after with FileNotFoundError: 'waydroid', since NixOS system
      # services otherwise get a minimal PATH that skips
      # /run/current-system/sw/bin.
      path = [ config.virtualisation.waydroid.package ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = installExtrasScript;
      };
    };

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

    # Narrowly scoped to exactly this one systemctl invocation on exactly
    # this one unit - not a general "run systemctl as root" grant.
    security.sudo.extraRules = lib.mkIf (cfg.extras != [ ]) [
      {
        users = [ config.myDesktop.primaryUser ];
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl start --wait waydroid-extras-install.service";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # User-level, but only as a trigger - it has to wait for a Waydroid
    # *session* - which only exists once someone's logged into the
    # graphical session and either opened a Waydroid app or run
    # `waydroid session start` themselves - not merely for
    # waydroid-container.service, which is up well before that and tells
    # you nothing about session state. Polls rather than hooking a
    # specific event, since nothing emits a clean "session started"
    # signal to wait on; gives up after 2 minutes so a host where nobody
    # ever starts a session doesn't spin forever every login. The actual
    # install work happens in waydroid-extras-install.service above, not
    # here (see top-of-file comment for why).
    systemd.user.services.waydroid-extras = lib.mkIf (cfg.extras != [ ]) {
      description = "Trigger Waydroid extras install once a session is up";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "waydroid-extras-wait-and-trigger" ''
          for i in $(seq 1 24); do
            if ${pkgs.waydroid}/bin/waydroid status 2>/dev/null | grep -qE "^Session:[[:space:]]*RUNNING"; then
              exec /run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start --wait waydroid-extras-install.service
            fi
            sleep 5
          done
          echo "waydroid-extras: no Waydroid session detected after 2 minutes, giving up for this login" >&2
        '';
      };
    };
  };
}
