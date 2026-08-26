# ../../modules/features/easyeffects.nix
{ config, lib, pkgs, ... }:

{
  options.myFeatures.easyeffects.enable =
    lib.mkEnableOption "EasyEffects audio processing";

  config = lib.mkIf config.myFeatures.easyeffects.enable {
    environment.systemPackages = [
      pkgs.easyeffects
    ];
  };
}
