# ../../modules/apps-user/cava.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.cava.enable =
    lib.mkEnableOption "Cava";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.cava.enable {
    home.packages = with pkgs; [
      cava
    ];
  };
}
