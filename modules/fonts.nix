{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  fonts.fontconfig.enable = true;
}
