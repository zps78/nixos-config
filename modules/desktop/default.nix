# ../../modules/desktop/default.nix
{ lib, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./kde.nix
    ./niri.nix
  ];

  options.myDesktop.stack = lib.mkOption {
    type = lib.types.enum [ "gnome" "kde" "niri" ];
    default = "niri";
    description = "Which desktop stack to enable for this host.";
  };
}
