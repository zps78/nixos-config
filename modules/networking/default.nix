# ../../modules/networking/default.nix
{
  imports = [
    ./core.nix
    ./tailscale.nix
    ./wifi.nix
  ];
}
