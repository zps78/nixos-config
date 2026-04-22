# ../../modules/gpu-nvidia.nix
{ config, pkgs, lib, ... }:

{
  ############################################################
  # NVIDIA GPU (Desktop - Single GPU)
  # RTX 4060 Ti
  ############################################################

  # Enable graphics stack
  hardware.graphics.enable = true;

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
  };

  # Wayland + NVIDIA fixes (cursor issues)
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
