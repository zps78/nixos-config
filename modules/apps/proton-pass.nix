# ../../modules/apps/darktable.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.darktable.enable =
    lib.mkEnableOption "Darktable";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.darktable.enable {
    home.packages = with pkgs; [
      darktable
    ];
  };
}
