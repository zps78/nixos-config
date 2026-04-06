{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Graphics
    bambu-studio
    darktable
    gimp
  ];
}
