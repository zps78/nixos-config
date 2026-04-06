{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Gaming
    lutris
    steam
    sunshine
  ];
}
