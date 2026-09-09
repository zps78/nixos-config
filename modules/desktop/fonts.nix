# ../../modules/desktop/fonts.nix
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    corefonts
    fira-sans
    font-awesome
    jetbrains-mono
    material-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.enable = true;
}
