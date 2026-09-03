# ../../modules/apps/spotatui.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.spotatui.enable =
    lib.mkEnableOption "Spotatui";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.spotatui.enable {
    home.packages = with pkgs; [
      spotatui
    ];
  };
}
