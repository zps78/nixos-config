# ../../modules/features/default.nix
{
  imports = [
    ./core.nix
    ./data-rescue.nix
    ./kde-connect.nix
    ./steam.nix
    ./wine.nix
  ];
}