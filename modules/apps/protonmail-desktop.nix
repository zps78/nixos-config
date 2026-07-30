# ../../modules/apps/protonmail-desktop.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.protonmail-desktop.enable =
    lib.mkEnableOption "Protonmail Desktop";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.protonmail-desktop.enable {
    home.packages = with pkgs; [
      protonmail-desktop
    ];
  };
}
