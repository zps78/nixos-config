# ../../modules/services/discovery.nix
{ config, pkgs, ... }:

{
  ############################################################
  # Avahi (mDNS / Zeroconf)
  ############################################################
  #
  # Enables:
  # - .local hostname discovery
  # - printer discovery
  # - NAS discovery
  # - Sunshine/Moonlight discovery
  # - AirPlay-like service discovery
  #
  # Example:
  #   nas.local
  #

  services.avahi = {
    enable = true;

    # Allow local hostname resolution via libc
    nssmdns4 = true;

    # Open firewall ports automatically
    openFirewall = true;
  };

  ############################################################
  # GVFS
  ############################################################
  #
  # Adds desktop integration for:
  # - SMB shares
  # - SFTP
  # - MTP
  # - network browsing
  #
  # Important for:
  # - Dolphin
  # - Nautilus
  # - GNOME Files
  #
  # Especially useful with NAS systems.
  #

  services.gvfs.enable = true;
}
