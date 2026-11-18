# ../../modules/storage/snapshots.nix
#
# Rolling ZFS snapshots with sanoid - the declarative successor of the
# Unraid karma's "zfs-autosnap" User Script. An UNDO, not a backup: the
# snapshots live on the same disks. Replication to other disks/the
# Synology (syncoid) comes once those exist.
#
# Pick a retention tier per dataset; datasets not listed get nothing (e.g.
# rpool/local/*, which is rebuildable). Tiers mirror the old karma job:
#   important  24 hourly, 30 daily, 3 monthly   (home, appdata, var, photos, docs)
#   library    48 hourly, 14 daily              (media - big churn, short memory)
#   vm         7 daily                          (VM disks)
#
# Restore: copy from /<mountpoint>/.zfs/snapshot/autosnap_<date>_<tier>/
# (hidden dir - type the path), or `zfs rollback` a whole dataset.
# Space: `zfs list -t snapshot -o name,used -s used`.
{ config, lib, ... }:

let
  cfg = config.myStorage.snapshots;
in
{
  options.myStorage.snapshots = {
    enable = lib.mkEnableOption "rolling ZFS snapshots (sanoid)";

    datasets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          tier = lib.mkOption {
            type = lib.types.enum [ "important" "library" "vm" ];
            description = "Retention tier (see the header of modules/storage/snapshots.nix).";
          };
          recursive = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Also snapshot every child dataset (each pruned on its own).";
          };
        };
      });
      default = { };
      example = { "rpool/safe" = { tier = "important"; }; };
      description = "Datasets to snapshot, with their retention tier.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.myStorage.zfs.enable;
        message = "myStorage.snapshots needs myStorage.zfs.enable."; }
    ];

    services.sanoid = {
      enable = true;
      interval = "hourly";

      templates = {
        important = { hourly = 24; daily = 30; monthly = 3; autosnap = true; autoprune = true; };
        library   = { hourly = 48; daily = 14; monthly = 0; autosnap = true; autoprune = true; };
        vm        = { hourly = 0;  daily = 7;  monthly = 0; autosnap = true; autoprune = true; };
      };

      datasets = lib.mapAttrs (_: d: {
        useTemplate = [ d.tier ];
        inherit (d) recursive;
      }) cfg.datasets;
    };
  };
}
