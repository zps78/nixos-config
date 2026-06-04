# ../../modules/hardware/bluetooth.nix
{ config, lib, ... }:

{
  options.myHardware.bluetooth = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this machine has Bluetooth hardware";
  };

  config = lib.mkIf config.myHardware.bluetooth {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
