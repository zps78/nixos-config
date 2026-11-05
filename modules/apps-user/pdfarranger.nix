# ../../modules/apps-user/pdfarranger.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.pdfarranger.enable =
    # on for every user unless a user file turns it off
    lib.mkEnableOption "PDF Arranger" // { default = true; };

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.pdfarranger.enable {
    home.packages = with pkgs; [
      pdfarranger # Merge or split pdf documents and rotate, crop and rearrange their pages using a graphical interface
    ];
  };
}
