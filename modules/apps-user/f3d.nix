# ../../modules/apps-user/f3d.nix
#
# 3mf thumbnails via f3d's own assimp plugin fail on real Bambu Studio
# exports (Assimp validation error: aiScene::mNumMeshes is 0) -
# confirmed against 6 real files, 100% failure. A cached thumbnail from
# 2026-09-03 (Thumb::MTime matching the file's current mtime, so not
# stale) proves it worked before, and a separate GNOME::
# ThumbnailFactory failure cached 2026-09-17 for the exact same file/
# mtime proves it broke somewhere in that window - almost certainly an
# f3d or Assimp version bump via a flake update. Worth reporting
# upstream / bisecting the regression at some point, but not worth
# leaving 3mf thumbnails broken in the meantime.
#
# modules/desktop/niri.nix and modules/desktop/gnome.nix now ship a
# real extraction-based model/3mf thumbnailer (pulls the slicer's own
# embedded preview PNG straight out of the 3mf's zip container, so it
# doesn't depend on Assimp parsing the model at all). For it to
# actually be used, f3d's own assimp-plugin thumbnailer can't go on
# claiming model/3mf too: GNOME's thumbnailer directory scan has no
# defined ordering when two .thumbnailer files claim the same
# mimetype (confirmed - this isn't a theoretical worry, it's exactly
# what silently broke the first attempt at this: see git history
# around commits 4dbcc00/b19961d for the full story), so whichever one
# "wins" is arbitrary rather than guaranteed to be the one that works.
# Stripped from f3d's thumbnailer's MimeType below so there's only one
# handler.
#
# Separate regression, found 2026-10-30: f3d 4.0.0's built-in
# "thumbnail" config (--config=thumbnail, used by every *.thumbnailer
# file here, including stl/obj/ply/gltf/step/...) now defaults to
# --no-background=true, rendering an RGBA PNG with a fully transparent
# background instead of the old solid #333333 fill - GNOME Files shows
# that as a checkerboard. Confirmed by diffing a real cached thumbnail
# (TrueColorAlpha, corner pixel srgba(0,0,0,0)) against a fresh render
# with --no-background=false appended (TrueColor, corner #333333 - f3d's
# own documented --background-color default). The CLI flag's own global
# default is still false; only the "thumbnail" config preset changed.
# Append --no-background=false to every thumbnailer's Exec line to
# restore the old solid-background look.
{ config, pkgs, lib, ... }:

{
  options.myApps.f3d.enable =
    lib.mkEnableOption "F3D";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.f3d.enable {
    home.packages = with pkgs; [
      (f3d.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          sed -i 's/;model\/3mf$//' $out/share/thumbnailers/f3d-plugin-assimp.thumbnailer
          sed -i 's/--resolution=%s,%s %i/--resolution=%s,%s --no-background=false %i/' \
            $out/share/thumbnailers/*.thumbnailer
        '';
      }))
    ];
  };
}
