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

    # UMU/Proton launches (Bottles, Lutris, etc.) fail silently during
    # pressure-vessel's container bootstrap: NixOS has no /sbin/ldconfig
    # or /usr/bin/ldconfig (only /run/current-system/sw/bin/ldconfig),
    # and pressure-vessel hardcodes those FHS paths to probe host library
    # architecture. envfs dynamically populates /bin and /usr/bin with
    # whatever's actually on PATH - NixOS's standard fix for exactly this
    # class of "third-party binary assumes FHS paths" issue. Also set in
    # steam.nix, since Steam's own Proton runtime hits the identical bug
    # independently of wine/Bottles.
    services.envfs.enable = true;
  };
}
