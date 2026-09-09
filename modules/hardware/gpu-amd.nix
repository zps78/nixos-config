# ../../modules/hardware/gpu-amd.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myHardware.gpuVendor == "amd") {
  ############################################################
  # AMD GPU (Laptop - Integrated GPU only)
  # ThinkPad X13 Gen 3 (Ryzen + Radeon iGPU)
  ############################################################

  # Graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for some apps (e.g. Steam, Wine)

    extraPackages = with pkgs; [
      libvdpau-va-gl
    ];
  };

  # amdgpu is an in-kernel KMS driver; no services.xserver.videoDrivers
  # entry needed for a Wayland-only session.

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };
}
