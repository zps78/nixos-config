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
# handler. f3d's other thumbnailers (stl/obj/ply/gltf/step/...) are
# untouched and still work fine.
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
        '';
      }))
    ];
  };
}
