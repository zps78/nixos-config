# ../../modules/apps/telegram.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.telegram.enable =
    lib.mkEnableOption "Telegram";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.telegram.enable {
    home.packages = with pkgs; [
      telegram-desktop
    ];
  };
}
