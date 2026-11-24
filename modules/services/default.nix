# ../../modules/services/default.nix
{
  imports = [
    ./adguard.nix
    ./ai-stack.nix
    ./alerts.nix
    ./avahi.nix
    ./battery.nix
    ./beszel.nix
    ./brother-ads-4300n.nix
    ./brother-hl-l8230cdw.nix
    ./cockpit.nix
    ./docker.nix
    ./gvfs.nix
    ./homepage.nix
    ./libvirt.nix
    ./paperless.nix
    ./samba.nix
    ./scrutiny.nix
    ./ssh.nix
    ./sunshine.nix
    ./vpn-torrent.nix
    ./waydroid.nix
    ./wol-web.nix
  ];
}
