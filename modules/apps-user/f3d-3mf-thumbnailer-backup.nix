# ../../modules/apps-user/f3d-3mf-thumbnailer-backup.nix
#
# PARKED, NOT IMPORTED ANYWHERE - not part of the active config. See
# f3d.nix for the full story: f3d's own assimp-plugin thumbnailer
# claims model/3mf but currently fails on real Bambu Studio exports
# (a genuine regression, not a permanent limitation - a cached
# thumbnail from 2026-09-03 proves it worked before something broke
# it, likely an f3d/Assimp version bump). This file extracts the
# slicer's own embedded preview PNG directly from the 3mf's zip
# container instead of rendering anything, sidestepping Assimp
# entirely - confirmed working against real files while f3d fails on
# every one of them.
#
# Only reach for this if the upstream regression doesn't get fixed /
# reported in a reasonable time and the 3mf thumbnail gap becomes
# worth routing around permanently. To activate: import this file from
# home/niri.nix (or wherever) and remove f3d's own conflicting
# model/3mf MimeType claim the same way the earlier attempt did (see
# git history around commit 4dbcc00 for the full working version,
# including the f3d.overrideAttrs postInstall sed) - both pieces are
# needed together, this file alone isn't enough while f3d still claims
# the same mime type.
{ pkgs, ... }:

let
  threeMfThumbnailer = pkgs.writeShellApplication {
    name = "3mf-thumbnailer";
    runtimeInputs = [ pkgs.unzip ];
    text = ''
      input="$1"
      output="$2"
      if ! unzip -p "$input" "Metadata/thumbnail.png" > "$output" 2>/dev/null || [ ! -s "$output" ]; then
        unzip -p "$input" "Metadata/plate_1.png" > "$output" 2>/dev/null || true
      fi
      [ -s "$output" ]
    '';
  };
in
{
  home.packages = [ threeMfThumbnailer ];

  xdg.dataFile."thumbnailers/3mf.thumbnailer".text = ''
    [Thumbnailer Entry]
    Exec=${threeMfThumbnailer}/bin/3mf-thumbnailer %i %o
    MimeType=application/vnd.ms-3mfdocument;model/3mf;
  '';
}
