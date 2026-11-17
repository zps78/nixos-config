# ../../modules/storage/zfs.nix
#
# ZFS on a NixOS host: kernel module, a ZFS-compatible kernel, monthly
# scrubs, TRIM, and which pools to import at boot.
#
# The root pool (the one / lives on) is imported by the initrd from
# hardware-configuration.nix's fileSystems entries. Data pools that are
# not needed to boot go in extraPools and are imported later by
# zfs-import.service.
#
# Pools coming from another OS (karma's Unraid disks disk1..disk5) carry
# that system's hostid, so the very first import has to be forced by
# hand - `zpool import -f -o readonly=on <pool>` to look, then without
# readonly - before they're added to extraPools. Never `zpool upgrade`
# them while Unraid is still the fallback.
{ config, lib, pkgs, ... }:

let
  cfg = config.myStorage.zfs;
in
{
  options.myStorage.zfs = {
    enable = lib.mkEnableOption "ZFS support";

    extraPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "disk1" "disk2" ];
      description = ''
        Non-root pools to import at boot. Only add a pool once it has been
        imported on this host at least once (see the header comment).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "zfs" ];

    # ZFS is an out-of-tree module and often lags the newest kernel, so
    # don't follow modules/system/boot.nix's linuxPackages_latest here:
    # nixpkgs' default kernel is the one its ZFS package is built against.
    boot.kernelPackages = pkgs.linuxPackages;

    # Pools are imported by name with no stale-hostid surprises: the host
    # sets its own hostid (networking.hostId) and forcing is never
    # automatic.
    boot.zfs.forceImportRoot = false;
    boot.zfs.forceImportAll = false;
    boot.zfs.extraPools = cfg.extraPools;

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      trim.enable = true;   # weekly zpool trim (SSD/NVMe pools; no-op on HDDs)
      # ZED mails/logs pool faults; notification target comes later.
      zed.settings.ZED_NOTIFY_VERBOSE = lib.mkDefault false;
    };
  };
}
