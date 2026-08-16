# ../../modules/hardware/wwan.nix
{ config, lib,pkgs, ... }:

{
  options.myHardware.wwan.enable =
    lib.mkEnableOption "WWAN modem support";

  config = {
    # WWAN disabled by default:
    # prevent mhi-pci-generic from binding to MHI devices.
    boot.blacklistedKernelModules = lib.mkIf (!config.myHardware.wwan.enable) [
      "mhi_pci_generic"
    ];

    # Only run ModemManager when WWAN support is requested.
    networking.modemmanager.enable =
      config.myHardware.wwan.enable;

    environment.systemPackages =
      lib.mkIf config.myHardware.wwan.enable [
        pkgs.libmbim
      ];
  };
}
