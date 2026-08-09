# ../../modules/apps/kate.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.kate.enable =
    lib.mkEnableOption "Kate";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.kate.enable {
    home.packages = with pkgs; [
      clang-tools
      kdePackages.kate
      marksman
      nil
    ];
  };
}
