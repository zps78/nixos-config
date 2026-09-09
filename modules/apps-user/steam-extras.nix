# ../../modules/apps-user/steam-extras.nix
#
# User-space companions to the system `myFeatures.steam` feature.
{ config, lib, pkgs, ... }:

{
  options.myApps.steam-extras.enable =
    lib.mkEnableOption "Steam extras (Proton manager, overlay, Vulkan tools)";

  config = lib.mkIf config.myApps.steam-extras.enable {
    home.packages = with pkgs; [
      protonup-qt   # manage GE-Proton / custom Proton builds
      mangohud      # performance overlay
      vulkan-tools  # vulkaninfo, vkcube, ...
    ];

    # protonup-qt installs into ~/.steam/root/compatibilitytools.d, which
    # Steam already scans by default; kept explicit to match prior intent.
    home.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        "$HOME/.steam/root/compatibilitytools.d";
    };
  };
}
