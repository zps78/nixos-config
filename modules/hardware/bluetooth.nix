# ../../modules/bluetooth.nix
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # KDE works fine without blueman, but it can be a useful fallback
  # services.blueman.enable = true;
}
