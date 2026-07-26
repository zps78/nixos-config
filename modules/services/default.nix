# ../../modules/services/default.nix
{
  imports = [
    ./brother-ads-4300n.nix
    ./brother-hl-l8230cdw.nix
    ./discovery.nix
    ./docker.nix
    ./hp-officejet-pro-8715.nix
    ./libvirt.nix
    ./ssh.nix
    ./sunshine.nix
    ./waydroid.nix
  ];
}
