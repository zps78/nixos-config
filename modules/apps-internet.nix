{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Internet
#    eddie
    brave
    filezilla
#    googleearth-pro
    scrcpy
    thunderbird
  ];
}
