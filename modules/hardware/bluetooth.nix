# ../../modules/hardware/bluetooth.nix
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;
}
