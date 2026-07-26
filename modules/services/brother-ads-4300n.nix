# ../../modules/services/brother-ads-4300n.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.brother-ads-4300n.enable =
    lib.mkEnableOption "Brother ADS-4300N network scanner";

  config = lib.mkIf config.myServices.brother-ads-4300n.enable {
    # Scanning (driverless via AirScan)
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };

    # Useful user tools
    environment.systemPackages = with pkgs; [
      simple-scan
    ];
  };
}
