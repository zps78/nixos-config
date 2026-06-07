# ../../modules/services/default.nix
{
  imports = [
    ./discovery.nix
    ./docker.nix
    ./hp-officejet-pro-8715.nix
    ./libvirt.nix
    ./ssh.nix
    ./sunshine.nix
    ./waydroid.nix
  ];
}
