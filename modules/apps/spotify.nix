# ../../modules/apps/spotify.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.spotify.enable =
    lib.mkEnableOption "Spotify";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.spotify.enable {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
