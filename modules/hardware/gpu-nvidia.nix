# ../../modules/hardware/gpu-nvidia.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myHardware.gpuVendor == "nvidia") {
  ############################################################
  # NVIDIA GPU (Desktop - Single GPU)
  # RTX 4060 Ti
  ############################################################

  # Enable graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Use NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Required for Wayland / Plasma 6
    modesetting.enable = true;

    # Desktop → no need for aggressive power saving
    powerManagement.enable = false;

    # Proprietary driver (best performance)
    open = false;

    # Optional GUI tool
    nvidiaSettings = true;

    # Adding an explicit driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland + NVIDIA stability
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  hardware.nvidia-container-toolkit.enable = true;

  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = true;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';
}
