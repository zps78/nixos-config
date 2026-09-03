# ../../modules/apps/plex-tui.nix
{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.myApps.plex-tui;
in
{
  options.myApps.plex-tui.enable =
    lib.mkEnableOption "Plex TUI";

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.plex-tui.packages.${pkgs.system}.default
    ];
  };
}
