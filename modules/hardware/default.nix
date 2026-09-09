# ../../modules/hardware/default.nix
{ lib, ... }:

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./fingerprint.nix
    ./gpu-amd.nix
    ./gpu-hybrid.nix
    ./gpu-intel.nix
    ./gpu-nvidia.nix
    ./keyboard.nix
    ./wwan.nix
  ];

  options.myHardware.gpuVendor = lib.mkOption {
    type = lib.types.enum [ "amd" "intel" "nvidia" "hybrid" ];
  };

  options.myHardware.ramGB = lib.mkOption {
    type = lib.types.ints.positive;
    description = "Installed RAM in GB for this host (drives adaptive zram/swap sizing).";
  };
}
