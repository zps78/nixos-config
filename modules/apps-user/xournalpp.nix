# ../../modules/apps-user/xournalpp.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.xournalpp.enable =
    lib.mkEnableOption "Xournal++";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.xournalpp.enable {
    home.packages = with pkgs; [
      xournalpp # Xournal++ is a handwriting Notetaking software with PDF annotation support
    ];
  };
}
