# ../../modules/hardware/memtest.nix
#
# MemTest86+ entry in the systemd-boot menu, for RAM testing without a USB
# stick. Off by default; enable per host when chasing instability.
{ config, lib, ... }:

{
  options.myHardware.memtest.enable =
    lib.mkEnableOption "MemTest86+ entry in the systemd-boot menu";

  config = lib.mkIf config.myHardware.memtest.enable {
    boot.loader.systemd-boot.memtest86.enable = true;
  };
}
