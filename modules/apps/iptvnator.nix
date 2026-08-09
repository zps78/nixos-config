# ../../modules/apps/iptvnator.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.iptvnator.enable =
    lib.mkEnableOption "IPTVnator";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.iptvnator.enable {
    home.packages = with pkgs; [
      iptvnator
    ];
  };
}
