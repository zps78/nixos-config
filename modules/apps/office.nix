# ../../modules/apps/office.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.office.enable =
    lib.mkEnableOption "OnlyOffice";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.office.enable {
    home.packages = with pkgs; [
      onlyoffice-desktopeditors
    ];
  };
}
