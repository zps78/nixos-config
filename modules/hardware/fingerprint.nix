# ../../modules/hardware/fingerprint.nix
{ config, lib, ... }:

{
  options.mySystem.hasFingerprint = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this machine has a fingerprint reader";
  };

  config = lib.mkIf config.mySystem.hasFingerprint {
    services.fprintd.enable = true;
  };
}
