# ../../modules/storage/default.nix
#
# NAS storage stack (karma). Each piece is opt-in via myStorage.*:
#   zfs.nix       - ZFS support, scrubs, TRIM, pool imports
#   snapshots.nix - rolling snapshots per dataset (sanoid), retention tiers
# Planned (see the NAS plan): mergerfs pool over the data disks,
# SnapRAID parity, syncoid replication, NFS/SMB exports.
{
  imports = [
    ./snapshots.nix
    ./zfs.nix
  ];
}
