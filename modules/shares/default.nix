# ../../modules/shares/default.nix
{
  imports = [
    ./nfs/mounts/nfs-backup.nix
    ./nfs/mounts/nfs-home.nix
    ./nfs/mounts/nfs-media.nix
    ./nfs/mounts/nfs-paperless.nix
    ./nfs/mounts/nfs-torrents.nix
    ./nfs/mounts/nfs-trading.nix
  ];
}
