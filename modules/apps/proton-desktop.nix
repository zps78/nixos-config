# ../../modules/apps/proton-desktop.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.proton-desktop.enable =
    lib.mkEnableOption "Proton Desktop";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.proton-desktop.enable {
    home.packages = with pkgs; [
      proton-desktop
    ];
  };
}
