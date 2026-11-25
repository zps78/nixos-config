# ../../modules/storage/default.nix
#
# NAS storage stack (karma). Each piece is opt-in via myStorage.*:
#   zfs.nix       - ZFS support, scrubs, TRIM, pool imports
#   snapshots.nix - rolling snapshots per dataset (sanoid), retention tiers
#   game-saves.nix - backup of game saves from the games SSD (every 6 h, only after playing)
#   status.nix    - ZFS pool status JSON for Homepage
# Planned (see the NAS plan): mergerfs pool over the data disks,
# SnapRAID parity, syncoid replication, NFS/SMB exports.
{
  imports = [
    ./game-saves.nix
    ./snapshots.nix
    ./status.nix
    ./zfs.nix
  ];
}
