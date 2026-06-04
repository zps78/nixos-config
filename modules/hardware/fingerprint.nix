# ../../modules/hardware/fingerprint.nix
{ config, lib, ... }:

{
  options.myHardware.fingerprint.enable =
    lib.mkEnableOption "Fingerprint reader";

  config = lib.mkIf config.myHardware.fingerprint.enable {
    services.fprintd.enable = true;
  };
}
