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

let
  cfg = config.my.services.sunshine;

  sunshinePkg =
    if cfg.gpuVendor == "nvidia" then
      pkgs.sunshine.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages;
      }
    else
      pkgs.sunshine;
in
{
  options.my.services.sunshine = {
    enable = lib.mkEnableOption "Sunshine host";

    gpuVendor = lib.mkOption {
      type = lib.types.enum [ "none" "nvidia" "amd" "intel" ];
      default = "none";
      description = "GPU vendor-specific Sunshine behavior to apply.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
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

        package = sunshinePkg;
      };

      systemd.user.services.sunshine = {
        after = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
    };
      environment.systemPackages = [
        sunshinePkg
      ];
    }

    (lib.mkIf (cfg.gpuVendor == "intel") {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vpl-gpu-rt
          intel-media-driver
        ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
      };

      services.sunshine.settings = {
        # Intel-specific Sunshine settings
      };
    })

    (lib.mkIf (cfg.gpuVendor == "amd") {
      services.sunshine.settings = {
        # AMD-specific Sunshine settings
      };
    })

    (lib.mkIf (cfg.gpuVendor == "nvidia") {
      services.sunshine.settings = {
        # NVIDIA-specific Sunshine settings
      };
    })
  ]);
}
