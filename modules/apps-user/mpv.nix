# ../../modules/apps-user/mpv.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.mpv.enable =
    lib.mkEnableOption "MPV";

  config = lib.mkIf config.myApps.mpv.enable {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
      ];
    };
  };
}
