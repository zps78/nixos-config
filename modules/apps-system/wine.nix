# ../../modules/apps-system/wine.nix
#
# Wine (staging, WoW64 build - 32- and 64-bit in one package, no multilib)
# plus winetricks. 32-bit graphics libs come from the host's GPU module
# (hardware.graphics.enable32Bit), so no hardware.graphics block here.
#
# DXVK / VKD3D are installed per-prefix with `winetricks dxvk vkd3d`, not
# system-wide.
{ config, lib, pkgs, ... }:

{
  options.myFeatures.wine.enable =
    lib.mkEnableOption "Wine";

  config = lib.mkIf config.myFeatures.wine.enable {
    environment.systemPackages = with pkgs; [
      wineWow64Packages.staging
      winetricks
    ];
  };
}
