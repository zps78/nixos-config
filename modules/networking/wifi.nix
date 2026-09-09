# modules/networking/wifi.nix
#
# WiFi capability module
#
# Purpose:
# - Enables modern WiFi backend (iwd)
# - Points NetworkManager at that backend
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
    # Uses iwd instead of wpa_supplicant: faster, simpler, more modern.
    # NetworkManager owns the connection profiles and autoconnect; iwd
    # just handles authentication and the radio.
    #

    networking.networkmanager.wifi.backend = "iwd";
    networking.wireless.iwd.enable = true;
  };
}
