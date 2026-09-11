# ../../modules/apps-user/steam-extras.nix
#
# User-space companions to the system `myFeatures.steam` feature.
# Automatic on any host with Steam enabled - not a separate per-user
# opt-in, since if Steam's on you want Proton management + the overlay
# + Vulkan diagnostics with it. No `myApps.steam-extras.enable` option.
{ lib, pkgs, osConfig, ... }:

{
  config = lib.mkIf osConfig.myFeatures.steam.enable {
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
