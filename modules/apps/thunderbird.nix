# ../../modules/apps/thunderbird.nix
{ config, lib, ... }:

{
  options.myApps.thunderbird.enable =
    lib.mkEnableOption "Thunderbird";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.thunderbird.enable {
    programs.thunderbird.enable = true;
  };
}
