# ../../modules/apps/losslesscut.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.losslesscut.enable =
    lib.mkEnableOption "LosslessCut";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.losslesscut.enable {
    home.packages = with pkgs; [
      losslesscut-bin
    ];
  };
}
