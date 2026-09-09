# ../../modules/apps-user/godot.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.godot.enable =
    lib.mkEnableOption "Godot";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.godot.enable {
    home.packages = with pkgs; [
      godot_4-mono   # Godot 4 with the C#/.NET module compiled in
      dotnet-sdk     # needed by Godot to build C# assemblies
    ];
  };
}
