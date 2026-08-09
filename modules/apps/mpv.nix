# ../../modules/apps/mpv.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.mpv.enable =
    lib.mkEnableOption "MPV";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.mpv.enable {
#    home.packages = with pkgs; [
#      mpv
#    ];
     programs.mpv = {
       enable = true;
       scripts = with pkgs.mpvScripts; [
         uosc
         thumbfast
       ];
     };
  };
}
