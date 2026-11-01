# ../../modules/apps-user/remmina.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.remmina.enable = lib.mkEnableOption "Remmina";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.remmina.enable {
    home.packages = with pkgs; [
      remmina
    ];
  };
}
