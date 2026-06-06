# ../../modules/apps/vlc.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.vlc.enable =
    lib.mkEnableOption "VLC";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.vlc.enable {
    home.packages = with pkgs; [
      vlc
    ];
  };
}
