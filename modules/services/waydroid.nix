# ../../modules/services/waydroid.nix
{ config, lib, ... }:

{
  options.myServices.waydroid.enable =
    lib.mkEnableOption "Waydroid";

  config = lib.mkIf config.myServices.waydroid.enable {
    virtualisation.waydroid.enable = true;
  };
}
