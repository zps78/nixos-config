# ../../modules/services/docker.nix
#
# Docker module for NixOS
#
# Provides:
# - Docker Engine
# - Docker CLI
# - Docker Compose v2
# - optional non-root access via docker group
#
# Notes:
# - Users must belong to the "docker" group
#   to run docker without sudo.
#
# Security warning:
# - docker group is effectively root access
#

{ pkgs, ... }:

{
  virtualisation.docker = {

    # Enable Docker daemon
    enable = true;

    # Enable Docker Compose v2 plugin
    #
    # Allows:
    #   docker compose up
    #
    enableOnBoot = true;

    # Optional:
    # Enable automatic pruning support later if desired
    autoPrune.enable = false;
  };

  environment.systemPackages = with pkgs; [

    # Optional but useful Docker tools

    # Interactive container management UI
    lazydocker

    # Better docker compose logging
    docker-compose

    # Container inspection/debugging
    dive
  ];
}
