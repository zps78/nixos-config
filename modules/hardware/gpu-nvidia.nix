# ../../modules/hardware/gpu-nvidia.nix
{ config, pkgs, lib, ... }:

{
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

# Outdated config settings:
#  # Wayland + NVIDIA fixes (cursor issues)
#  environment.sessionVariables = {
#    WLR_NO_HARDWARE_CURSORS = "1";
#  };

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
