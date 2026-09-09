# ../../modules/services/battery.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.battery.enable =
    lib.mkEnableOption "Battery support";

  config = lib.mkIf config.myServices.battery.enable {

    services.upower.enable = true;

    powerManagement.enable = true;

    # upower itself comes from services.upower.enable
    environment.systemPackages = with pkgs; [
      acpi
      powertop
    ];

  };
}
