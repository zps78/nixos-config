# ../../modules/apps-system/data-rescue.nix
#
# Data recovery / disk rescue toolkit. Enable on machines where you do
# disk recovery, forensic inspection or filesystem repair.
#
# Note: parted, smartmontools, hdparm, nvme-cli, file and e2fsprogs are
# already always present (system/packages.nix / the ext filesystem
# module), so this list only adds what's missing.
{ config, lib, pkgs, ... }:

{
  options.myFeatures.data-rescue.enable =
    lib.mkEnableOption "Data recovery / disk rescue tools";

  config = lib.mkIf config.myFeatures.data-rescue.enable {
    environment.systemPackages = with pkgs; [
      # Recovery / undelete
      ddrescue      # recover data from failing drives
      ddrescueview  # GUI for ddrescue mapfiles
      ddrutility    # analyse disk damage / recovery cases
      testdisk      # partition recovery + file undelete

      # Partitioning (GUI)
      gparted

      # Filesystem tools not in the base set
      ntfs3g        # NTFS read/write + ntfsfix / ntfsclone
      btrfs-progs   # Btrfs recovery + inspection
      exfatprogs    # exFAT tools

      # Media diagnostics
      f3            # fight flash fraud (fake capacity SD/USB)
      fio           # I/O benchmark - check a recovered drive's health/speed
      hexedit       # inspect/edit raw disk data
      sysbench      # CPU/memory/disk sanity check on suspect hardware
    ];
  };
}
