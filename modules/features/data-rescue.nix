# ../../modules/features/data-rescue.nix
#
# Data recovery / disk rescue toolkit
#
# Enable only on machines where you do:
# - disk recovery
# - forensic inspection
# - filesystem repair
#
{ config, lib, pkgs, ... }:

{
  options.myFeatures.data-rescue.enable =
    lib.mkEnableOption "Data recovery / disk rescue tools";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myFeatures.data-rescue.enable {
    environment.systemPackages = with pkgs; [

      ############################################################
      # Core recovery tools (your requested set)
      ############################################################
      ddrescue         # GNU ddrescue - recover data from failing drives
      ddrescueview     # GUI for ddrescue mapfiles (visual progress analysis)
      ddrutility       # Utilities for analyzing disk damage / recovery cases
      testdisk         # Partition recovery + file undelete toolkit

      ############################################################
      # Recommended additions (very useful in real recoveries)
      ############################################################

      gparted          # Partition editor (GUI, extremely useful in recovery)
      parted           # CLI partition manipulation

      ntfs3g           # NTFS read/write support (common recovery scenario)
      e2fsprogs        # ext4/ext3/ext2 tools (fsck, debugfs, resize2fs)
      btrfs-progs      # Btrfs recovery + inspection tools
      exfatprogs       # exFAT support tools

      smartmontools    # SMART disk health inspection (predict failure)

      hdparm           # low-level disk inspection & tuning
      nvme-cli         # NVMe-specific diagnostics (critical for modern SSDs)
      f3               # fight flash fraud

      file             # identify unknown file types in broken filesystems

      hexedit          # manual inspection/editing of raw disk data
    ];
  };
}
