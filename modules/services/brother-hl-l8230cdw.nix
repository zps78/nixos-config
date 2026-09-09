# ../../modules/services/brother-hl-l8230cdw.nix
{ config, lib, pkgs, ... }:

let
  queue = "Brother-HL-L8230CDW";
  uri = "ipp://192.168.1.100/ipp/print";
  ppd = ./ppd/brother-hl-l8230cdw.ppd;
in
{
  options.myServices.brother-hl-l8230cdw.enable =
    lib.mkEnableOption "Brother HL-L8230CDW network printer";

  config = lib.mkIf config.myServices.brother-hl-l8230cdw.enable {
    # Printing (driverless)
    services.printing.enable = true;

    # Enable IPP-over-USB (for USB contingency connection)
    services.ipp-usb.enable = true;

    # Don't run cups-browsed: it auto-creates discovered queues that
    # duplicate the one configured below. (Default is services.avahi.enable.)
    services.printing.browsed.enable = false;

    # Configure the queue from a static PPD (captured from `-m everywhere`).
    #
    # NOT hardware.printers.ensurePrinters: that only passes `lpadmin -m`,
    # and this CUPS won't take a PPD path there - only `-m everywhere`,
    # which needs the printer online at every rebuild. `-P <ppd>` does not
    # touch the network, so the queue survives offline rebuilds.
    systemd.services.ensure-brother-hl-l8230cdw = {
      description = "Configure the ${queue} CUPS queue";
      wantedBy = [ "multi-user.target" ];
      wants = [ "cups.service" ];
      after = [ "cups.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.cups ];
      script = ''
        lpadmin -p ${queue} -v ${uri} -P ${ppd} \
          -o PageSize=A4 -o Duplex=DuplexNoTumble -E
        lpadmin -d ${queue}
      '';
    };

    # Useful user tools
#    environment.systemPackages = with pkgs; [
#     system-config-printer
#     simple-scan
#    ];
  };
}
