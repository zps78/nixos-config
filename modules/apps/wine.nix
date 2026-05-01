# ../../modules/apps/wine.nix
# Provides:
# - Wine (staging branch)
# - 32-bit + 64-bit Windows compatibility
# - Winetricks helper scripts
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    # Wine Staging (WoW64)
    #
    # Includes:
    # - 64-bit Wine support
    # - 32-bit Wine support
    #
    # "Staging" contains newer experimental patches
    # that often improve:
    # - gaming compatibility
    # - launcher compatibility
    # - DirectX behavior
    wineWowPackages.staging

    # Wine helper utility
    #
    # Used for:
    # - installing DLLs
    # - configuring Wine prefixes
    # - applying compatibility tweaks
    # - installing fonts/components
    winetricks
  ];
}
