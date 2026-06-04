# ../../modules/hardware/bluetooth.nix
{ config, lib, ... }:

{
  options.myHardware.bluetooth.enable =
    lib.mkEnableOption "Bluetooth support";

  config = lib.mkIf config.myHardware.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
