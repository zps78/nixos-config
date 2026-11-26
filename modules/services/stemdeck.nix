# ../../modules/services/stemdeck.nix
#
# StemDeck: splits songs into stems (vocals, drums, bass, ...) with Demucs
# on the NVIDIA GPU, web UI. No nixpkgs package - the upstream container,
# run through virtualisation.oci-containers by the host's backend (kraken:
# Podman, unit podman-stemdeck.service, visible in Cockpit), GPU via CDI
# (hardware.nvidia-container-toolkit).
#
#   http://127.0.0.1:<port>  for the tunnel only: outside localhost StemDeck
#                            insists on HTTPS (browsers allow its audio
#                            engine only in a secure context) and accepts a
#                            proxy's X-Forwarded-Proto - so it's used through
#                            the tunnel (https), never on a plain LAN port.
#                            (Container port rules bypass the NixOS firewall
#                            anyway: never publish on 0.0.0.0.)
#
# Data under dataDir: cache/ (model weights, re-downloadable), jobs/ (the
# library: registry.json, audio, stems), settings.json. The image's
# entrypoint chowns them to PUID:PGID at every start (kraken: 99:100 =
# media:users).
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.stemdeck;
in
{
  options.myServices.stemdeck = {
    enable = lib.mkEnableOption "StemDeck (stem separation, GPU)";

    image = lib.mkOption {
      type = lib.types.str;
      # pinned to the version karma ran at the move (2026-11-26); update
      # deliberately: docker pull ghcr.io/stemdeckapp/stemdeck:latest and
      # take its RepoDigest
      default = "ghcr.io/stemdeckapp/stemdeck@sha256:01cb2d129c1d0f3cfc5b9d93c5a51bc776c6a53158fb0ec00b0d9b50cb744904";
    };

    port = lib.mkOption { type = lib.types.port; default = 8010; };

    listenAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "127.0.0.1" ];
      description = "Host addresses to publish the port on (127.0.0.1 = the tunnel).";
    };

    dataDir = lib.mkOption { type = lib.types.str; default = "/srv/appdata/stemdeck"; };

    uid = lib.mkOption { type = lib.types.int; default = 99; };
    gid = lib.mkOption { type = lib.types.int; default = 100; };

    maxDurationSec = lib.mkOption { type = lib.types.int; default = 1200; description = "Longest song accepted."; };
    maxPendingJobs = lib.mkOption { type = lib.types.int; default = 3; };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (config.virtualisation.podman.enable || config.virtualisation.docker.enable) && config.hardware.nvidia-container-toolkit.enable;
        message = "myServices.stemdeck needs Podman (or Docker) and hardware.nvidia-container-toolkit."; }
    ];

    virtualisation.oci-containers.containers.stemdeck = {
      image = cfg.image;
      ports = map (a: "${a}:${toString cfg.port}:8000") cfg.listenAddresses;
      volumes = [
        "${cfg.dataDir}/cache:/cache"
        "${cfg.dataDir}/jobs:/app/jobs"
        "${cfg.dataDir}/settings.json:/app/settings.json"
      ];
      environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        STEMDECK_MAX_DURATION_SEC = toString cfg.maxDurationSec;
        STEMDECK_MAX_PENDING_JOBS = toString cfg.maxPendingJobs;
        STEMDECK_PERSIST_LIBRARY = "1";
        TZ = config.time.timeZone;
      };
      extraOptions = [ "--device=nvidia.com/gpu=all" ];
    };

    # settings.json must exist as a file, or Docker creates a directory there
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${cfg.dataDir}/cache 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "d ${cfg.dataDir}/jobs 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      "f ${cfg.dataDir}/settings.json 0644 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # don't start on an unmounted /srv/appdata
    systemd.services."${config.virtualisation.oci-containers.backend}-stemdeck".unitConfig.RequiresMountsFor = [ cfg.dataDir ];
  };
}
