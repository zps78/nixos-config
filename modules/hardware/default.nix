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
  ];

  options.myHardware.gpuVendor = lib.mkOption {
    type = lib.types.enum [ "amd" "intel" "nvidia" "hybrid" ];
  };
}
