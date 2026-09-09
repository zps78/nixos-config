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
      f3d
    ];
  };
}
