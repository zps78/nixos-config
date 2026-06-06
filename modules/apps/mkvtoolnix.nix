# ../../modules/apps/mkvtoolnix.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.mkvtoolnix.enable =
    lib.mkEnableOption "MKVToolNix";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.mkvtoolnix.enable {
    home.packages = with pkgs; [
      mkvtoolnix
    ];
  };
}
