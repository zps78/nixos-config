# ../../modules/apps/godot.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.godot.enable = lib.mkEnableOption "Godot";

  config = lib.mkIf config.myApps.godot.enable {
    home.packages = with pkgs; [
      godot
      mono
      dotnet-sdk
    ];
  };
}