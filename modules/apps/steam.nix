# ../../modules/apps/steam.nix
# Minimal Steam gaming module for NixOS
#
# Optional companion modules:
# - lutris.nix
# - sunshine.nix
# - gamescope.nix (future)

{ pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/wine.nix
  ];

  programs.steam = {

    # Enable Steam
    #
    # This automatically configures:
    # - Steam package
    # - required runtime support
    # - 32-bit compatibility libraries
    # - Vulkan integration
    # - OpenGL support
    #
    enable = true;

    # Opens firewall ports for Steam Remote Play
    #
    # Allows:
    # - streaming games to another device
    # - Remote Play Together
    #
    # Safe to leave enabled on trusted networks.
    remotePlay.openFirewall = true;

    # Opens firewall ports for Steam LAN transfers
    #
    # Allows Steam clients on the same network
    # to transfer installed games locally instead
    # of downloading them again from the internet.
    #
    # Useful if you have multiple gaming machines.
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.gamemode = {

    # Automatically optimizes system performance
    # while games are running.
    enable = true;
  };

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

    # Proton management utility
    protonup-qt

    # Performance overlay
    mangohud

    # Vulkan debugging utilities
    vulkan-tools
  ];

  environment.sessionVariables = {

    # Additional Proton compatibility tools path
    #
    # Allows Steam to discover manually installed
    # Proton versions inside:
    #
    # ~/.steam/root/compatibilitytools.d
    #
    # Common use:
    # - GE-Proton
    # - custom Proton builds
    #
    STEAM_EXTRA_COMPAT_TOOLS_PATHS =
      "$HOME/.steam/root/compatibilitytools.d";
  };
}
