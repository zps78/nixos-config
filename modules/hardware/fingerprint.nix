# ../../modules/hardware/fingerprint.nix
{ config, lib, ... }:

{
  options.myHardware.fingerprint = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this machine has a fingerprint reader";
  };

  config = lib.mkIf config.myHardware.fingerprint {
    services.fprintd.enable = true;
  };
}
