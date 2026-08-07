# ../../modules/services/battery.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.battery.enable =
    lib.mkEnableOption "Battery support";

  config = lib.mkIf config.myServices.battery.enable {

    services.upower.enable = true;

    powerManagement.enable = true;

    environment.systemPackages = with pkgs; [
      upower
      acpi
      powertop
    ];

  };
}
