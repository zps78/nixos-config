# home/niri.nix  — or merge into your existing home/<user>.nix
{ config, pkgs, ... }:

{
  # Companion bar, locker, notifications via HM modules
  programs.waybar.enable = true;
  programs.alacritty.enable = true;
  programs.fuzzel.enable = true;
  programs.swaylock.enable = true;
  services.mako.enable = true;
  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "niri msg action power-off-monitors"; }
    ];
  };

  # Drop a KDL config via xdg.configFile; edit the source path to taste.
  # You can also manage it fully in Nix via the niri-flake HM module,
  # but this gives you a plain KDL file you can live-reload.
  # xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}