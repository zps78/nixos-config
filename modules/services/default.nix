# ../../modules/services/default.nix
{
  imports = [
    ./avahi.nix
    ./battery.nix
    ./brother-ads-4300n.nix
    ./brother-hl-l8230cdw.nix
    ./docker.nix
    ./gvfs.nix
    ./libvirt.nix
    ./ssh.nix
    ./sunshine.nix
    ./waydroid.nix
  ];
}
