# ../../modules/desktop/default.nix
{ lib, ... }:

{
  imports = [
    ../../modules/desktop/fonts.nix
    ../../modules/desktop/gnome.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/kde.nix
    ../../modules/desktop/niri.nix
  ];

  options.myDesktop.stack = lib.mkOption {
    type = lib.types.enum [ "gnome" "hyprland" "kde" "niri" ];
  };
}
