# ../../modules/hardware/bluetooth.nix
{ config, lib, ... }:

{
  options.mySystem.hasBluetooth = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this machine has Bluetooth hardware";
  };

  config = lib.mkIf config.mySystem.hasBluetooth {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
