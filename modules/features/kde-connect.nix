# modules/features/kde-connect.nix
{ config, lib, ... }:

{
  options.myFeatures.kde-connect.enable =
    lib.mkEnableOption "KDE Connect";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myFeatures.kde-connect.enable {
    programs.kdeconnect.enable = true;
  };
}
