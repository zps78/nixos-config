# ../../modules/apps/wine.nix
# Provides:
# - Wine (staging branch)
# - 32-bit + 64-bit Windows compatibility
# - Winetricks helper scripts
{ pkgs, ... }:

{
  hardware.graphics = {

    # Required for:
    # - OpenGL
    # - Vulkan
    # - GPU acceleration
    enable = true;

    # Required for:
    # - Steam
    # - Proton
    # - Wine
    # - many older Linux games
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [

    # Wine
    # Includes:
    # - 64-bit Wine support
    # - 32-bit Wine support
    wineWow64Packages.staging

    # Wine helpers
    winetricks

    # Vulkan translation layers
    dxvk
    vkd3d
  ];
}
