# ../../modules/services/rustdesk.nix
#
# RustDesk remote desktop module for NixOS
#
# Provides:
# - RustDesk client
# - RustDesk service
# - Firewall configuration
#
# Supports:
# - unattended access
# - Wayland
# - X11
# - LAN + internet remote desktop
#
# Usage:
#
# imports = [
#   ../../modules/services/rustdesk.nix
# ];
#
# Optional:
# - self-hosted RustDesk server
# - Wayland desktop sharing
#

{ pkgs, ... }:

{
  # -------------------------------------------------
  # RustDesk package
  # -------------------------------------------------
  environment.systemPackages = with pkgs; [
    rustdesk-flutter # Virtual / remote desktop infrastructure for everyone! Open source TeamViewer / Citrix alternative
  ];

  # -------------------------------------------------
  # Enable RustDesk service
  # -------------------------------------------------
  services.rustdesk = {
    enable = true;

    # Open required firewall ports automatically
    openFirewall = true;
  };

  # -------------------------------------------------
  # Notes
  # -------------------------------------------------
  #
  # First launch:
  #
  #   rustdesk
  #
  # You can then:
  # - set unattended password
  # - connect via RustDesk ID
  # - configure relay/server
  #
  # -------------------------------------------------
  # Wayland notes
  # -------------------------------------------------
  #
  # For Hyprland / Wayland:
  #
  # Screen sharing works best with:
  #
  #   xdg-desktop-portal-hyprland
  #   pipewire
  #
  # If using your ml4w setup,
  # you likely already have these.
  #
  # -------------------------------------------------
  # Optional self-hosted server
  # -------------------------------------------------
  #
  # RustDesk supports:
  #
  # - hbbs (ID server)
  # - hbbr (relay server)
  #
  # Can be added later on a VPS or NAS.
  #
}
