# ../../modules/hardware/gpu-hybrid.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myHardware.gpuVendor == "hybrid") {
  ############################################################
  # Hybrid GPU (Intel + NVIDIA) configuration
  # - Intel iGPU handles display
  # - NVIDIA used via PRIME offload
  ############################################################

  # Kernel comes from system/boot.nix (linuxPackages_latest). If a flake
  # update lands a kernel newer than nvidiaPackages.stable supports, pin
  # `boot.kernelPackages = pkgs.linuxPackages;` here or switch to
  # nvidiaPackages.beta until it catches up.

  # Enable graphics stack. The Intel iGPU drives display + video decode,
  # so it needs the same VA-API stack as the intel-only hosts.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver  # VA-API / iHD
      vpl-gpu-rt          # oneVPL / QSV runtime
      libvdpau-va-gl      # only if something needs VDPAU translation
    ];
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

  # Intel iGPU is primary
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
