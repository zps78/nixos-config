# ../../home/stylix.nix
{ pkgs, ... }:

{
  stylix = {
    enable = true;

    base16Scheme =
      "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    targets.firefox.profileNames = [ "default" ];
    targets.zen-browser.profileNames = [ "default" ];
    overlays.enable = false;
  };
}
