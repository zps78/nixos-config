# modules/networking/wifi.nix
#
# WiFi capability module
#
# Purpose:
# - Enables modern WiFi backend (iwd)
# - Configures NetworkManager WiFi behavior
#
# This module does NOT:
# - enable NetworkManager
# - configure DNS
# - configure firewall
# - define system networking profile
#

{ config, lib, ... }:

{
  options.myNetwork.wifi.enable =
    lib.mkEnableOption "Wifi iwd backend activation";

  config = lib.mkIf config.myNetwork.wifi.enable {
    ############################################################
    # NetworkManager WiFi backend
    ############################################################
    #
    # Uses iwd instead of wpa_supplicant.
    # iwd is faster, simpler, and more modern.
    #

    networking.networkmanager.wifi.backend = "iwd";

    ############################################################
    # iwd daemon
    ############################################################
    #
    # Required when using iwd backend in NetworkManager.
    # Handles authentication + connection management.
    #
    # AutoConnect:
    # reconnect automatically to known networks.
    #
    networking.wireless.iwd = {
      enable = true;

      settings = {
        Settings = {
          AutoConnect = true;
        };
      };
    };
  };
}
