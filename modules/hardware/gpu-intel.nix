# ../../modules/hardware/gpu-intel.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myHardware.gpuVendor == "intel") {
  ############################################################
  # Intel iGPU
  # ThinkPad X12 Ultra 7 164U
  # ThinkCentre M920q / i7-8700T
  ############################################################

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for Steam/Wine and some desktop apps

    extraPackages = with pkgs; [
      intel-media-driver  # VA-API / iHD
      vpl-gpu-rt          # oneVPL / QSV runtime
      libvdpau-va-gl      # only if something needs VDPAU translation
    ];
  };

  services.xserver.videoDrivers = [ "modesetting" ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
