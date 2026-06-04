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

{ config, lib, pkgs, ... }:

{
  options.myServices.sunshine.enable =
    lib.mkEnableOption "Sunshine host";

  config = lib.mkIf config.myServices.sunshine.enable {
    hardware.uinput.enable = true;

    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    services.sunshine = {
      # Enable the Sunshine service
      enable = true;
      # Automatically start Sunshine at boot
      autoStart = true;

      # Grants CAP_SYS_ADMIN capability - required for:
      # - input device capture
      # - virtual input devices
      # - controller support
      capSysAdmin = true;

      # Opens required firewall ports automatically - required for:
      # - Moonlight discovery
      # - streaming connections
      openFirewall = true;
    };

    # Proper Firewall Configuration
    networking.firewall = {
      allowedTCPPorts = [ 47984 47989 47990 ];
      allowedUDPPortRanges = [ { from = 47998; to = 48010; } ];
      # Extra rule for safety
      extraInputRules = ''
        udp dport 47998-48100 accept
      '';
    };
    environment.systemPackages = [ pkgs.sunshine ];
  };
}
