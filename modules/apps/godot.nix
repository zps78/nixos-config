# ../../modules/apps/godot.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.godot.enable = 
    lib.mkEnableOption "Godot";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.godot.enable {
    home.packages = with pkgs; [
      godot
      mono
      dotnet-sdk
    ];
  };
}