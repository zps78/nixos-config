# ../../modules/services/sunshine.nix
#
# Web UI:
#   https://<host-ip>:47990
#
# First launch:
#   1. Start Sunshine
#   2. Open the web UI
#   3. Create username/password
#   4. Pair using Moonlight client

{ config, lib, pkgs, ... }:

{
  options.myServices.sunshine = {
    enable = lib.mkEnableOption "Sunshine host";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "enp5s0" ];
      description = ''
        Open Sunshine's ports only on these network interfaces (plus
        tailscale0, which the fleet already trusts). Empty = open them on
        every interface, the upstream default (krieger).
      '';
    };
  };

  config = lib.mkIf config.myServices.sunshine.enable {
    # Per-interface firewall instead of upstream's global openFirewall.
    # Same ports upstream derives from the base port (47989 by default):
    # TCP -5/0/+1/+21, UDP +9/+10/+11/+13/+21.
    networking.firewall.interfaces = lib.genAttrs config.myServices.sunshine.interfaces (_:
      let base = config.services.sunshine.settings.port; in {
        allowedTCPPorts = map (o: base + o) [ (-5) 0 1 21 ];
        allowedUDPPorts = map (o: base + o) [ 9 10 11 13 21 ];
      });

    # Provides the uinput device + udev rule for virtual input capture.
    hardware.uinput.enable = true;

    # /dev/uinput's udev rule (from hardware.uinput.enable) sets
    # GROUP="uinput" - NOT "input" (a different, unrelated group; that
    # earlier assumption was wrong and left virtual mouse/keyboard/gamepad
    # creation permission-denied even with a fresh login session). Follows
    # sessionUser (the account whose session Sunshine runs in; defaults to
    # primaryUser) instead of a manually-toggled group entry in each
    # host's configuration.nix.
    users.users.${config.myDesktop.sessionUser}.extraGroups = [ "uinput" ];

    # /dev/uhid is a separate kernel device from /dev/uinput above - Sunshine
    # uses it specifically for virtual *gamepad* emulation (uinput covers
    # mouse/keyboard), and hardware.uinput.enable doesn't touch it at all.
    # Without this, Sunshine's own log shows it failing outright: "create
    # libvirtualhid gamepad: failed to open /dev/uhid: Permission denied" -
    # meaning controller input through Moonlight never actually works.
    # Reuses the same "uinput" group rather than inventing a new one, since
    # sessionUser is already in it for the reason above.
    services.udev.extraRules = ''
      KERNEL=="uhid", MODE="0660", GROUP="uinput"
    '';

    # Requests the CPU performance governor (and other optimizations) while
    # a game is running. Without it, Proton games silently fail to apply
    # this at all: "gamemodeauto: dlopen failed - libgamemode.so: cannot
    # open shared object file" spams the log on every launch because the
    # library the game is trying to dlopen was never installed.
    programs.gamemode.enable = true;

    services.sunshine = {
      enable = true;
      autoStart = true;

      # CAP_SYS_ADMIN: needed for input device / virtual input capture.
      capSysAdmin = true;

      # (see security.wrappers.sunshine below for CAP_SYS_NICE)

      # Opens the streaming + discovery ports (derived from the configured
      # port) on every interface - unless myServices.sunshine.interfaces
      # narrows them down (see above).
      openFirewall = config.myServices.sunshine.interfaces == [ ];

      # nixpkgs' sunshine build is CUDA-less by default, so NVENC fails
      # at runtime with "Cannot load libcuda.so.1" and silently falls
      # back to software (libx264) encoding - libcuda.so.1 is present
      # at the standard /run/opengl-driver/lib path, the package just
      # wasn't built to look for it there. cudaSupport bakes the right
      # LD_LIBRARY_PATH into the build's own wrapper script, which
      # survives the separate capSysAdmin security wrapper on top
      # (known nixpkgs issue: NixOS/nixpkgs#272221, #305688).
      # "hybrid" (Intel+NVIDIA PRIME) hosts have a real NVIDIA GPU too -
      # same fix applies, not just plain "nvidia".
      package = lib.mkIf (builtins.elem config.myHardware.gpuVendor [ "nvidia" "hybrid" ])
        (pkgs.sunshine.override { cudaSupport = true; });
    };

    # Upstream's capSysAdmin wrapper grants only cap_sys_admin. Sunshine
    # also asks the GPU for a high-priority EGL context, which needs
    # CAP_SYS_NICE - without it every stream start logs "EGL: context
    # priority set to HIGH but CAP_SYS_NICE capability is missing" and the
    # capture/encode context competes with the game at normal priority.
    # The NixOS wrapper raises its permitted caps into the ambient set, so
    # Sunshine ends up with both effective (same as cap_sys_admin today).
    security.wrappers.sunshine.capabilities =
      lib.mkIf config.services.sunshine.capSysAdmin
        (lib.mkForce "cap_sys_admin,cap_sys_nice+p");
  };
}
