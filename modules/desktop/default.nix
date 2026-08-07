# ../../modules/desktop/default.nix
{ lib, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./hyprland.nix
    ./kde.nix
    ./niri.nix
  ];

  options.myDesktop.stack = lib.mkOption {
    type = lib.types.enum [ "gnome" "hyprland" "kde" "niri" ];
  };
}
