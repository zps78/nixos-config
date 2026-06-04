# ../../modules/system/default.nix
{
  imports = [
    ../../modules/system/auth.nix
    ../../modules/system/boot.nix
    ../../modules/system/common.nix
    ../../modules/system/localization.nix
    ../../modules/system/memory.nix
  ];
}