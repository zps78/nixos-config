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

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Public keys (not secret - fine to commit plain-text) allowed to
        log in as this host's myDesktop.primaryUser, in addition to
        whatever's already in ~/.ssh/authorized_keys. Used for the
        fleet's cross-host admin keys (see secrets/secrets.nix and
        home/users/zp.nix for the private-key side).
      '';
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

      # openssh's own NixOS default for this is `true` - explicitly
      # overriding to false here, NOT just omitting the option (omitting
      # it inherits the upstream true). That default opens the port on
      # every interface, not just LAN - harmless under IPv4 (NAT meant
      # nothing not explicitly port-forwarded was reachable from outside
      # regardless) but a real internet-facing exposure once a host
      # holds a routable IPv6 address, since the same physical interface
      # then carries both a LAN-reachable and a globally-routable
      # address with no way to tell them apart at the firewall level.
      # Confirmed via a live external IPv6 port scan against kuro: SSH
      # was reachable from the open internet with this left at its
      # default. Access instead relies entirely on Tailscale's trusted
      # interface (modules/networking/tailscale.nix's
      # trustedInterfaces = [ "tailscale0" ]), which every host in this
      # fleet already uses exclusively for remote access.
      openFirewall = false;
    };

    users.users.${config.myDesktop.primaryUser}.openssh.authorizedKeys.keys =
      cfg.authorizedKeys;

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
