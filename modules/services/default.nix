# ../../modules/services/default.nix
{
  imports = [
    ./battery.nix
    ./brother-ads-4300n.nix
    ./brother-hl-l8230cdw.nix
    ./discovery.nix
    ./docker.nix
    ./libvirt.nix
    ./ssh.nix
    ./sunshine.nix
    ./waydroid.nix
  ];
}
