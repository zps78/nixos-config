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

{ config, lib, ... }:

{
  options.myServices.sunshine.enable =
    lib.mkEnableOption "Sunshine host";

  config = lib.mkIf config.myServices.sunshine.enable {
    # Provides the uinput device + udev rule for virtual input capture.
    hardware.uinput.enable = true;

    services.sunshine = {
      enable = true;
      autoStart = true;

      # CAP_SYS_ADMIN: needed for input device / virtual input capture.
      capSysAdmin = true;

      # Opens the streaming + discovery ports (derived from the configured
      # port) and installs sunshine's own udev rules.
      openFirewall = true;
    };
  };
}
