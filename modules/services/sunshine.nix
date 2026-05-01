# ../../modules/services/sunshine.nix
#
# Web UI:
#   https://<host-ip>:47990
#
# First launch:
#   1. Start Sunshine
#   2. Open the web UI
#   3. Create username/password
#   4. Pair using Moonlight client
#

{ pkgs, ... }:

{
  services.sunshine = {

    # Enable the Sunshine service
    enable = true;

    # Automatically start Sunshine at boot
    #
    # Recommended for:
    # - desktop gaming systems
    # - always-on streaming hosts
    #
    # Disable if you prefer manual startup.
    autoStart = true;

    # Grants CAP_SYS_ADMIN capability
    #
    # Required for:
    # - input device capture
    # - virtual input devices
    # - controller support
    #
    # Usually recommended unless troubleshooting.
    capSysAdmin = true;

    # Opens required firewall ports automatically
    #
    # Required for:
    # - Moonlight discovery
    # - streaming connections
    #
    # Recommended unless you manage firewall rules manually.
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    # Optional but useful:
    #
    # Provides Sunshine CLI tools and binaries
    # directly in the shell environment.
    sunshine
  ];
}
