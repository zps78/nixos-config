# ../../modules/apps-user/f3d.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.f3d.enable =
    lib.mkEnableOption "F3D";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.f3d.enable {
    home.packages = with pkgs; [
      # f3d's assimp-plugin thumbnailer claims model/3mf, but its
      # underlying Assimp 3MF import genuinely fails on real slicer
      # exports (confirmed against a real Bambu Studio file: "Assimp
      # error: Validation failed: aiScene::mNumMeshes is 0" - Assimp's
      # 3MF support doesn't handle how Bambu structures multi-object/
      # multi-plate files). Stripped from its thumbnailer's MimeType so
      # it doesn't compete with the extraction-based one in niri.nix
      # that's confirmed to actually work (that file's slicer-rendered
      # preview lives inside the 3mf's own zip container, extracting it
      # doesn't depend on Assimp parsing the model at all). f3d's other
      # thumbnailers (stl/obj/ply/gltf/step/...) are untouched.
      (f3d.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          sed -i 's/;model\/3mf$//' $out/share/thumbnailers/f3d-plugin-assimp.thumbnailer
        '';
      }))
    ];
  };
}
