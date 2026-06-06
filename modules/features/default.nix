# ../../modules/features/default.nix
{
  imports = [
    ./core.nix
    ./data-rescue.nix
    ./steam.nix
    ./wine.nix
  ];
}