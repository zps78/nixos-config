# ../../modules/services/ssh.nix
{ config, lib, ... }:

let
  cfg = config.myServices.ssh;
in
{
  options.myServices.ssh = {
    enable = lib.mkEnableOption "SSH server";

    passwordAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (not recommended)";
    };

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 22 ];
      description = "SSH ports to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.ports;

      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = cfg.passwordAuth;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;
        X11Forwarding = false;
      };

      # Open firewall for all interfaces (LAN + Tailscale)
      openFirewall = true;
    };

    ############################################################
    # Optional: OpenSSH client QoL
    ############################################################
    #
    # Makes SSH-based desktop workflows nicer.
    #
    # Safe on almost all systems.
    #

    programs.ssh.startAgent = true;
  };
}
