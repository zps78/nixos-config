# ../../modules/networking/nfs-client.nix
#
# NFS client configuration for NixOS desktops/workstations.
#
# Use case:
# - Mount NAS shares automatically at boot
# - Support unRAID / Synology / Linux NFS servers
# - Integrates cleanly with systemd mounts
#
# Requires:
# - NFS server reachable on network
# - rpcbind enabled (usually needed for NFSv3; safe for v4 too)

{ config, pkgs, lib, ... }:

{
  ############################################################
  # Enable NFS client support in kernel/userspace
  ############################################################

  # Adds NFS filesystem support to the system
  boot.supportedFilesystems = [ "nfs" ];

  # RPC binding service (needed for some NFS setups)
  services.rpcbind.enable = true;

  ############################################################
  # Improve file manager behavior
  ############################################################
  #
  # Helps managers behave better with network FS.
  #

  environment.systemPackages = with pkgs; [
    nfs-utils
  ];
}
