# ../../modules/services/ai-stack.nix
#
# Local AI stack for GPU-equipped hosts: Ollama (LLM serving) + Open WebUI
# (chat frontend) + ComfyUI (Stable Diffusion / image generation), all with
# GPU passthrough.
#
# Claude (via Desktop/Code + the freecad-mcp addon, see
# modules/apps-user/freecad.nix) remains the FreeCAD driver - this stack is
# for general local chat/coding assistance and image generation instead.
# Local models' tool-calling isn't reliable enough yet for multi-step CAD
# scripting, so there's no attempt here to wire Ollama into FreeCAD.
#
# Requires hardware.nvidia-container-toolkit.enable (set automatically by
# modules/hardware/gpu-nvidia.nix when myHardware.gpuVendor == "nvidia"),
# which generates a CDI spec exposing the GPU as "nvidia.com/gpu=all". That
# device string is passed straight to `docker run --device=...` below -
# no legacy "nvidia" docker runtime is registered on these hosts, so
# --gpus/--runtime nvidia (seen in most images' own quickstart docs) won't
# work here; --device is the CDI-native equivalent and was verified
# directly against a throwaway container before writing this module.
{ config, lib, pkgs, ... }:

let
  cfg = config.myServices.aiStack;
  dataDir = "/var/lib/ai-stack";
  gpuOptions = [ "--device=nvidia.com/gpu=all" ];

  # Every container needs this ordering - the custom network has to exist
  # first, and docker's own service has to be up before any of it.
  dependsOnNetwork = {
    after = [ "docker-network-ai-stack.service" ];
    requires = [ "docker-network-ai-stack.service" ];
  };
in
{
  options.myServices.aiStack.enable =
    lib.mkEnableOption "local AI stack (Ollama + Open WebUI + ComfyUI) with GPU passthrough";

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    # User-defined bridge network so containers can reach each other by
    # name (open-webui -> ollama) - the default docker0 bridge has no
    # built-in container DNS. Idempotent: `network create` errors if it
    # already exists, which is the normal case on every rebuild/reboot
    # after the first, so check first instead of letting the unit fail.
    systemd.services."docker-network-ai-stack" = {
      description = "Create the ai-stack docker network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "create-ai-stack-network" ''
          ${pkgs.docker}/bin/docker network inspect ai-stack >/dev/null 2>&1 \
            || ${pkgs.docker}/bin/docker network create ai-stack
        ''}";
      };
    };

    virtualisation.oci-containers.containers = {
      # LLM serving. Published only on krieger's own Tailscale address (its
      # ollama API has no auth of its own) so other machines on the tailnet
      # - namely kuro's GPT4FreeCAD addon, see modules/apps-user/freecad.nix
      # - can reach it as http://krieger:11434, without exposing it on the
      # LAN too. open-webui still reaches it over the ai-stack network, by
      # container name, regardless of this.
      ollama = {
        image = "ollama/ollama:latest";
        volumes = [ "${dataDir}/ollama:/root/.ollama" ];
        ports = [ "100.101.102.33:11434:11434" ];
        extraOptions = gpuOptions ++ [ "--network=ai-stack" ];
      };

      # Chat frontend for ollama. Published on :3000 - first visit creates
      # the local admin account (WEBUI_AUTH is on by default).
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434";
        };
        volumes = [ "${dataDir}/open-webui:/app/backend/data" ];
        ports = [ "3000:8080" ];
        extraOptions = [ "--network=ai-stack" ];
        dependsOn = [ "ollama" ];
      };

      # Stable Diffusion / image generation. Single volume at /root covers
      # models, input, output and workflows together since it's a solo
      # host - no need for the six-way split the image's own quickstart
      # suggests for shared/multi-deploy setups.
      comfyui = {
        image = "yanwk/comfyui-boot:cu128-slim";
        volumes = [ "${dataDir}/comfyui:/root" ];
        ports = [ "8188:8188" ];
        extraOptions = gpuOptions ++ [ "--network=ai-stack" ];
      };
    };

    systemd.services."docker-ollama" = dependsOnNetwork;
    systemd.services."docker-open-webui" = dependsOnNetwork;
    systemd.services."docker-comfyui" = dependsOnNetwork;
  };
}
