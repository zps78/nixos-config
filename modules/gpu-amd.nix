# ../../modules/gpu-amd.nix
{ config, pkgs, lib, ... }:

{
  ############################################################
  # AMD GPU (Laptop - Integrated GPU only)
  # ThinkPad X13 Gen 3 (Ryzen + Radeon iGPU)
  ############################################################

  # Graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for some apps (e.g. Steam, Wine)

    extraPackages = with pkgs; [
#      mesa
#      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Use AMD driver (optional but explicit)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Wayland / app compatibility tweaks
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    LIBVA_DRIVER_NAME = "radeonsi";
  };
}
