# ../../modules/services/beszel.nix
#
# Beszel: metrics with history and alerts - CPU, RAM, temperatures, GPU
# (nvidia-smi), disk and network throughput. Hub = web app (own accounts,
# created on first visit); agent = the collector on each monitored host.
#
#   http://<host>:8090
#
# Two-step setup:
#   1. enable the hub, open it, create the admin account;
#   2. "Add system" in the hub shows its PUBLIC key - put it in agentKey
#      (public, fine in the repo) and rebuild; the agent starts and the
#      hub connects to it on 45876 (local only, not opened in the firewall).
#
# The agent deliberately gets NO Docker access: the upstream module adds
# it to the docker group whenever Docker is on, and the socket is
# root-equivalent. Per-container stats can be turned on later
# (dockerAccess = true) if wanted.
{ config, lib, ... }:

let
  cfg = config.myServices.beszel;
  port = 8090;
in
{
  options.myServices.beszel = {
    hub = {
      enable = lib.mkEnableOption "Beszel hub (web app)";
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Open the hub port only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
      };
    };

    agentKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "ssh-ed25519 AAAA...";
      description = "The hub's public key (shown under \"Add system\"). The agent only runs once this is set.";
    };

    rootDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "nvme0n1";
      description = ''
        Device for the root disk's I/O stats (the agent's FILESYSTEM). Set it
        when / isn't a plain partition (ZFS) - the agent otherwise guesses,
        e.g. by an unrelated partition labelled "root".
      '';
    };

    dockerAccess = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Let the agent read the Docker socket for per-container stats (root-equivalent access).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.hub.enable {
      services.beszel.hub = {
        enable = true;
        host = "0.0.0.0";
        inherit port;
      };

      networking.firewall.interfaces = lib.genAttrs cfg.hub.interfaces (_: {
        allowedTCPPorts = [ port ];
      });
    })

    (lib.mkIf (cfg.agentKey != null) {
      services.beszel.agent = {
        enable = true;
        openFirewall = false;
        environment = {
          KEY = cfg.agentKey;
        } // lib.optionalAttrs (cfg.rootDevice != null) {
          FILESYSTEM = cfg.rootDevice;
        };
      };

      systemd.services.beszel-agent.serviceConfig.SupplementaryGroups = lib.mkIf (!cfg.dockerAccess)
        (lib.mkForce [ "systemd-journal" ]);
    })
  ];
}
