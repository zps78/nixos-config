# ../../modules/gpu-hybrid.nix
{ config, pkgs, lib, ... }:

{
  ############################################################
  # Hybrid GPU (Intel + NVIDIA) configuration
  # - Intel iGPU handles display
  # - NVIDIA used via PRIME offload
  ############################################################

  # Enable graphics stack
  hardware.graphics.enable = true;

  # Use NVIDIA driver (with modesetting)
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA configuration
  hardware.nvidia = {
    # Required for Wayland / modern setups
    modesetting.enable = true;

    # Power management (IMPORTANT for laptops)
    powerManagement = {
      enable = true;
      finegrained = true;  # reduces idle power usage
    };

    # Use proprietary driver (recommended)
    open = false;

    # Enables nvidia-settings tool
    nvidiaSettings = true;

    # PRIME offload setup
    prime = {
      offload.enable = true;

      # Your specific PCI IDs (keep these as-is)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
