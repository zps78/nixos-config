# ../../modules/networking/tailscale.nix
{ config, lib, ... }:

{
  options.myNetwork.tailscale.enable =
    lib.mkEnableOption "Tailscale";

  config = lib.mkIf config.myNetwork.tailscale.enable {
    services.tailscale = {
      enable = true;

    # ----------------------------
    # Needed for --accept-routes to behave properly
    # ----------------------------
      useRoutingFeatures = "client";

    # ----------------------------
    # Not auto-applied in manual mode, but good to keep
    # ----------------------------
      extraUpFlags = [
        "--accept-dns"
        "--accept-routes"
        "--ssh"
      ];
    };

    # ----------------------------
    # Firewall integration
    # ----------------------------
    services.tailscale.openFirewall = true;
  };
}
