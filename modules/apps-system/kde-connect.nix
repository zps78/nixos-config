# ../../modules/apps-system/kde-connect.nix
{ config, lib, ... }:

{
  options.myFeatures.kde-connect.enable =
    lib.mkEnableOption "KDE Connect";

  # programs.kdeconnect installs kdeconnect-kde system-wide, runs the
  # daemon, and opens TCP/UDP 1714-1764. Do NOT also add the package in
  # home config - that gives disabled hosts a non-working app.
  config = lib.mkIf config.myFeatures.kde-connect.enable {
    programs.kdeconnect.enable = true;
  };
}
