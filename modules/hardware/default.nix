# ../../modules/hardware/default.nix
{ lib, config, ... }:

{
  imports =
    [
      ./audio.nix
      ./bluetooth.nix
      ./fingerprint.nix
    ]
    ++ lib.optionals (config.myHardware.gpuVendor == "amd") [
      ./gpu-amd.nix
    ]
    ++ lib.optionals (config.myHardware.gpuVendor == "nvidia") [
      ./gpu-nvidia.nix
    ]
    ++ lib.optionals (config.myHardware.gpuVendor == "intel") [
      ./gpu-intel.nix
    ]
    ++ lib.optionals (config.myHardware.gpuVendor == "hybrid") [
      ./gpu-hybrid.nix
    ];

  options.myHardware.gpuVendor = lib.mkOption {
    type = lib.types.enum [ "amd" "intel" "nvidia" "hybrid" ];
  };
}