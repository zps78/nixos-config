# ../../modules/apps-system/steam.nix
# Steam gaming module for NixOS (system bits only).
#
# User-space companions live in apps-user: bottles, lutris. Proton
# management (protonup-qt), overlays (mangohud) and
# STEAM_EXTRA_COMPAT_TOOLS_PATHS belong in the user's home config.

{ config, lib, ... }:

{
  options.myFeatures.steam.enable =
    lib.mkEnableOption "Steam";

  config = lib.mkIf config.myFeatures.steam.enable {
    programs.steam = {
      # Sets up the Steam package, FHS runtime, 32-bit libs, Vulkan/GL.
      enable = true;

      # Remote Play: stream games to another device / Remote Play Together.
      remotePlay.openFirewall = true;

      # LAN game transfers between local Steam clients.
      localNetworkGameTransfers.openFirewall = true;
    };

    # Optimises system performance while games run.
    programs.gamemode.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # Steam / Proton / 32-bit games
    };
  };
}
