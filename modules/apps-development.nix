{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Development
    godot
    vscode
  ];
}
