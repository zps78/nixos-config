# ../../modules/system/memory.nix
{ config, lib, ... }:

let
  # Total RAM in MB (provided by NixOS)
  ramMB = config.hardware.memorySize or 0;

  # Convert to GB
  ramGB = ramMB / 1024;

  # ----------------------------
  # Adaptive logic
  # ----------------------------

  # ZRAM percentage scaling
  zramPercent =
    if ramGB <= 16 then 50
    else if ramGB <= 32 then 35
    else if ramGB <= 64 then 25
    else if ramGB <= 128 then 15
    else 10;

  # Swapfile size (MB)
  swapSize =
    if ramGB <= 16 then 8192
    else if ramGB <= 64 then 4096
    else 0; # disable on large RAM systems

in
{
  # ----------------------------
  # ZRAM (primary swap)
  # ----------------------------
  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault zramPercent;
  };

  # ----------------------------
  # Disk swap (fallback)
  # ----------------------------
  swapDevices = lib.mkDefault (
    if swapSize == 0 then [ ]
    else [
      {
        device = "/swapfile";
        size = swapSize;
      }
    ]
  );

  # ----------------------------
  # Kernel tuning (important for zram)
  # ----------------------------
  boot.kernel.sysctl = {
    # Prefer swapping to zram instead of killing processes
    "vm.swappiness" = lib.mkDefault 100;

    # Avoid swapping tiny amounts constantly
    "vm.page-cluster" = lib.mkDefault 0;
  };
}
