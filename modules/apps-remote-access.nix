{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Remote access
    moonlight-qt
    remmina
    teamviewer
  ];
}
