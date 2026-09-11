# ../../modules/apps-user/lutris.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.lutris.enable =
    lib.mkEnableOption "Lutris";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.lutris.enable {
    home.packages = [
      # steamSupport is for importing/launching Steam-owned games from
      # inside Lutris's UI - not used here. Steam is the primary library
      # (modules/apps-system/steam.nix); Lutris only manages a few local
      # titles, surfaced into Steam via its own "Add to Steam" /
      # Non-Steam-Game entry. Dropping it saves ~2GB of bundled Steam
      # with no functional loss for that workflow.
      (pkgs.lutris.override { steamSupport = false; })
    ];
  };
}
