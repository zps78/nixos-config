# ../../modules/storage/default.nix
#
# NAS storage stack (karma). Each piece is opt-in via myStorage.*:
#   zfs.nix       - ZFS support, scrubs, TRIM, pool imports
# Planned (see the NAS plan): mergerfs pool over the data disks,
# SnapRAID parity, sanoid/syncoid snapshots + replication, NFS/SMB exports.
{
  imports = [
    ./zfs.nix
  ];
}
