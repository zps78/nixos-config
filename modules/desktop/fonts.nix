# ../../modules/desktop/fonts.nix
{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    fira-sans
    jetbrains-mono
    material-symbols
    nerd-fonts.fira-code
  ];

  fonts.fontconfig.enable = true;
}
