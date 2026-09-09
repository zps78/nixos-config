# ../../modules/hardware/gpu-nvidia.nix
{ config, lib, ... }:

lib.mkIf (config.myHardware.gpuVendor == "nvidia") {
  ############################################################
  # NVIDIA GPU (Desktop - Single GPU)
  # RTX 4060 Ti
  ############################################################

  # Kernel comes from system/boot.nix (linuxPackages_latest). If a flake
  # update lands a kernel newer than nvidiaPackages.stable supports, pin
  # `boot.kernelPackages = pkgs.linuxPackages;` here or switch to
  # nvidiaPackages.beta until it catches up.

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

    # Desktop: no runtime power saving, but still preserve VRAM across
    # suspend and wire up the nvidia-suspend/resume/hibernate services.
    powerManagement.enable = true;

    # Proprietary driver (best performance)
    open = false;

    # Optional GUI tool
    nvidiaSettings = true;

    # Adding an explicit driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia-container-toolkit.enable = true;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];
}
