# ../../modules/apps-user/pdfarranger.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.pdfarranger.enable =
    lib.mkEnableOption "PDF Arranger";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.pdfarranger.enable {
    home.packages = with pkgs; [
      pdfarranger # Merge or split pdf documents and rotate, crop and rearrange their pages using a graphical interface
    ];
  };
}
