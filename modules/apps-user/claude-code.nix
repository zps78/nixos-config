# ../../modules/apps-user/claude-code.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.claude-code.enable =
    lib.mkEnableOption "Claude Code CLI";

  config = lib.mkIf config.myApps.claude-code.enable {
    home.packages = with pkgs; [
      claude-code
    ];
  };
}
