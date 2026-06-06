# ../../modules/apps/krita.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.krita.enable =
    lib.mkEnableOption "Krita";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.krita.enable {
    home.packages = with pkgs; [
      krita
    ];
  };
}
