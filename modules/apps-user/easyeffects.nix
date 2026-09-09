# ../../modules/apps-user/easyeffects.nix
{ config, lib, pkgs, ... }:

{
  options.myApps.easyeffects.enable =
    lib.mkEnableOption "EasyEffects audio processing";

  config = lib.mkIf config.myApps.easyeffects.enable {
    home.packages = [ pkgs.easyeffects ];
  };
}
