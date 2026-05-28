# ../../modules/hardware/gpu-hybrid.nix
{ config, pkgs, lib, ... }:

{
  ############################################################
  # Hybrid GPU (Intel + NVIDIA) configuration
  # - Intel iGPU handles display
  # - NVIDIA used via PRIME offload
  ############################################################

  # Enable graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Your specific PCI IDs (keep these as-is)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Recommended for Wayland/NVIDIA
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  # Better Electron/Chromium Wayland support
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Optional suspend/resume helpers
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
}
