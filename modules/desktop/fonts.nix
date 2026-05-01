# ../../modules/desktop/fonts.nix
{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    corefonts
    fira-sans
    jetbrains-mono
    material-symbols
    nerd-fonts.fira-code
    vista-fonts
  ];

  fonts.fontconfig.enable = true;
}
