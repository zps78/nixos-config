# ../../modules/services/brother-hl-l8230cdw.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.brother-hl-l8230cdw.enable =
    lib.mkEnableOption "Brother HL-L8230CDW network printer";

  config = lib.mkIf config.myServices.brother-hl-l8230cdw.enable {
    # Printing (driverless)
    services.printing.enable = true;

    # Enable IPP-over-USB (for USB contingency connection)
    services.ipp-usb.enable = true;

    # Auto-configure network printer (home)
    hardware.printers.ensurePrinters = [
      {
        name = "Brother-HL-L8230CDW";
        deviceUri = "ipp://192.168.1.100/ipp/print";
        model = "everywhere";

        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
    ];
    
    hardware.printers.ensureDefaultPrinter =
      "Brother-HL-L8230CDW";

    # Useful user tools
    environment.systemPackages = with pkgs; [
  #   system-config-printer
  #   simple-scan
    ];
  };
}
