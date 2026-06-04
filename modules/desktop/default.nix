# ../../modules/desktop/default.nix
{
  imports = [
    ../../modules/desktop/fonts.nix
    ../../modules/desktop/gnome.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/kde.nix
    ../../modules/desktop/niri.nix
  ];
}
