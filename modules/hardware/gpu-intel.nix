# ../../modules/hardware/gpu-intel.nix
{ config, pkgs, lib, ... }:

{
  ############################################################
  # Intel iGPU
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

  # Optional, but often useful on Intel systems
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
