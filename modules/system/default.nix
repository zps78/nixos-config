# ../../modules/system/default.nix
{
  imports = [
    ./auth.nix
    ./boot.nix
    ./common.nix
    ./localization.nix
    ./memory.nix
  ];
}