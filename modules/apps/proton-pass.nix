# ../../modules/apps/proton-pass.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.proton-pass.enable =
    lib.mkEnableOption "Proton Pass";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.proton-pass.enable {
    home.packages = with pkgs; [
      proton-pass
    ];
  };
}
