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
  options.myServices.sunshine.enable =
    lib.mkEnableOption "Sunshine host";

  config = lib.mkIf config.myServices.sunshine.enable {
    # Provides the uinput device + udev rule for virtual input capture.
    hardware.uinput.enable = true;

    # /dev/uinput's udev rule (from hardware.uinput.enable) sets
    # GROUP="uinput" - NOT "input" (a different, unrelated group; that
    # earlier assumption was wrong and left virtual mouse/keyboard/gamepad
    # creation permission-denied even with a fresh login session). Follows
    # primaryUser automatically instead of a manually-toggled group entry
    # in each host's configuration.nix.
    users.users.${config.myDesktop.primaryUser}.extraGroups = [ "uinput" ];

    services.sunshine = {
      enable = true;
      autoStart = true;

      # CAP_SYS_ADMIN: needed for input device / virtual input capture.
      capSysAdmin = true;

      # Opens the streaming + discovery ports (derived from the configured
      # port) and installs sunshine's own udev rules.
      openFirewall = true;

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
  };
}
