# ../../modules/services/brother-ads-4300n.nix
{ config, lib, pkgs, ... }:

let
  # The ADS-4300N supports eSCL but does NOT advertise _uscan._tcp over
  # mDNS (only Brother's proprietary _scanner._tcp), so sane-airscan's
  # auto-discovery never finds it. Pin the eSCL endpoint explicitly.
  #
  # mkAfter forces this last in hardware.sane.extraBackends, so
  # mkSaneConfig's "last wins" symlink resolution picks this airscan.conf
  # over the stock one (services.ipp-usb also appends sane-airscan).
  #
  # discovery = disable: use only the pinned device below - no mDNS/WSD
  # probing, and no chance of a duplicate entry if the scanner ever starts
  # advertising eSCL over mDNS.
  airscanConf = pkgs.writeTextFile {
    name = "airscan-conf-brother-ads-4300n";
    destination = "/etc/sane.d/airscan.conf";
    text = ''
      [devices]
      "Brother ADS-4300N" = http://192.168.1.101/eSCL/, escl

      [options]
      discovery = disable
    '';
  };
in
{
  options.myServices.brother-ads-4300n.enable =
    lib.mkEnableOption "Brother ADS-4300N network scanner";

  config = lib.mkIf config.myServices.brother-ads-4300n.enable {
    # Scanning (driverless via eSCL / AirScan)
    hardware.sane = {
      enable = true;
      extraBackends = lib.mkMerge [
        [ pkgs.sane-airscan ]
        (lib.mkAfter [ airscanConf ])
      ];
    };

    # Useful user tools
    environment.systemPackages = with pkgs; [
      simple-scan
    ];
  };
}
