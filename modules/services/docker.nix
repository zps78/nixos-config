# ../../modules/services/docker.nix
#
# Docker module for NixOS
#
# Provides:
# - Docker Engine
# - Docker CLI
# - optional non-root access via docker group
#
# Notes:
# - Users must belong to the "docker" group
#   to run docker without sudo.
#
# Security warning:
# - docker group is effectively root access
#
{ config, lib, pkgs, ... }:

{
  options.myServices.docker.enable =
    lib.mkEnableOption "Docker container host";

  config = lib.mkIf config.myServices.docker.enable {
    virtualisation.docker = {

      # Enable Docker daemon
      enable = true;

      # Start Docker automatically at boot
      enableOnBoot = true;

      # Optional:
      # Enable automatic pruning support later if desired
      autoPrune.enable = false;
    };

    environment.systemPackages = with pkgs; [

      # Optional but useful Docker tools

      # Interactive container management UI
      lazydocker

      # Container inspection/debugging
      dive
    ];
  };
}
