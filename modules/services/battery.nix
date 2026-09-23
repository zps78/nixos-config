# ../../modules/services/battery.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.battery = {
    enable = lib.mkEnableOption "Battery support";
    tlp.enable = lib.mkEnableOption "TLP power management (AC/battery policies, fan-friendly CPU limits)";
    tlp.usbDenylist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "06cb:00bd" ];
      description = "USB vendor:product IDs excluded from TLP autosuspend (fingerprint reader, Bluetooth); differs per machine.";
    };
  };

  config = lib.mkIf config.myServices.battery.enable (lib.mkMerge [
    {
      services.upower.enable = true;
      powerManagement.enable = true;

      # upower itself comes from services.upower.enable
      environment.systemPackages = with pkgs; [
        acpi
        powertop
      ];
    }

    # TLP replaces power-profiles-daemon (the two conflict), so hosts that
    # enable it get AC/battery switching without a manual profile toggle.
    # GNOME's own module turns power-profiles-daemon on by default
    # (services.power-profiles-daemon.enable = mkDefault true, for its
    # Settings power panel) - a plain `false` here outranks that default
    # and wins, which is what surfaced this: it was never actually
    # exercised until a GNOME host enabled TLP too.
    (lib.mkIf config.myServices.battery.tlp.enable {
      services.power-profiles-daemon.enable = false;

      services.tlp = {
        enable = true;
        settings = {
          # Intel HWP: only "powersave" (with an energy preference) and
          # "performance" exist, so the preference does the real work.
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

          # Firmware profile (drives the ThinkPad fan curve) plus no turbo
          # on battery - together the main fix for heat and fan ramping.
          PLATFORM_PROFILE_ON_AC = "balanced";
          PLATFORM_PROFILE_ON_BAT = "low-power";
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;

          # Optional battery-care charge limit, off by default (0/100 = no limit).
          # START_CHARGE_THRESH_BAT0 = 75;
          # STOP_CHARGE_THRESH_BAT0 = 80;
        }
        # USB autosuspend stays on, minus the per-host devices that
        # misbehave when suspended (fingerprint reader, Bluetooth adapter).
        // lib.optionalAttrs (config.myServices.battery.tlp.usbDenylist != [ ]) {
          USB_DENYLIST = lib.concatStringsSep " " config.myServices.battery.tlp.usbDenylist;
        };
      };
    })
  ]);
}
