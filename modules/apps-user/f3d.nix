# ../../modules/apps-user/f3d.nix
#
# 3mf thumbnails via f3d's own assimp plugin currently fail on real
# Bambu Studio exports (Assimp validation error: aiScene::mNumMeshes is
# 0) - confirmed against 6 real files, 100% failure live. But this is a
# genuine regression, not a permanent limitation: a cached thumbnail
# from 2026-09-03 (Thumb::MTime matching the file's current mtime, so
# not stale) proves it worked before, and a separate GNOME::
# ThumbnailFactory failure cached 2026-09-17 for the exact same file/
# mtime proves it broke somewhere in that window - almost certainly an
# f3d or Assimp version bump via a flake update. Left as plain f3d
# rather than patched around it: worth reporting upstream / bisecting
# the actual regression instead of routing around it permanently.
# modules/apps-user/f3d-3mf-thumbnailer-backup.nix has a working
# extraction-based fallback (confirmed against real files) parked and
# unused, ready to import if this doesn't get a real fix.
{ config, pkgs, lib, ... }:

{
  options.myApps.f3d.enable =
    lib.mkEnableOption "F3D";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.f3d.enable {
    home.packages = with pkgs; [
      f3d
    ];
  };
}
