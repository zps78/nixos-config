# ../../modules/apps/orca-slicer.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.orca-slicer.enable =
    lib.mkEnableOption "Orca-slicer";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.orca-slicer.enable {
    home.packages = with pkgs; [
      orca-slicer
    ];
  };
}
