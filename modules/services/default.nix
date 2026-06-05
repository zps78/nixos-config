# ../../modules/services/default.nix
{
  imports = [
    ./discovery.nix
    ./docker.nix
    ./libvirt.nix
    ./hp-officejet-pro-8715.nix
    ./ssh.nix
    ./sunshine.nix
    ./waydroid.nix
  ];
}
