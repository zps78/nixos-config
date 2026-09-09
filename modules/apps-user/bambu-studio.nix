# ../../modules/apps-user/bambu-studio.nix
{ config, pkgs, lib, osConfig, ... }:

let
  gpu = osConfig.myHardware.gpuVendor;
  # nixpkgs' withNvidiaGLWorkaround forces mesa/zink GL - needed on
  # nvidia / hybrid hosts to avoid GLEW/GL crashes in the app.
  bambu-studio = pkgs.bambu-studio.override {
    withNvidiaGLWorkaround = gpu == "nvidia" || gpu == "hybrid";
  };
in
{
  options.myApps.bambu-studio.enable =
    lib.mkEnableOption "Bambu-studio";

  config = lib.mkIf config.myApps.bambu-studio.enable {
    home.packages = [ bambu-studio ];
  };
}
