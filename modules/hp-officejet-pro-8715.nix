{ config, pkgs, lib, ... }:

{
  # Printing (driverless)
  services.printing.enable = true;

  # Enable IPP-over-USB (for USB connection at parents)
  services.ipp-usb.enable = true;

  # Auto-configure network printer (home)
  hardware.printers.ensurePrinters = [
    {
      name = "OfficeJet-8715";
      deviceUri = "ipp://192.168.1.100/ipp/print";
      model = "everywhere";
      ppdOptions = {
        PageSize = "A4";
        Duplex = "DuplexNoTumble";
      };
    }

    # Optional: USB printer (only active when plugged in)
#    {
#      name = "OfficeJet-USB";
#      deviceUri = "ipp://localhost:60000/ipp/print";
#      model = "everywhere";
#    }
  ];

  hardware.printers.ensureDefaultPrinter = "OfficeJet-8715";

  # Scanning (driverless via AirScan)
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  services.saned.enable = true;

  # Useful user tools
  environment.systemPackages = with pkgs; [
    system-config-printer
    simple-scan
  ];
}
