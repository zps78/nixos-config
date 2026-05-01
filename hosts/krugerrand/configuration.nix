# ../../hosts/krugerrand/configuration.nix
{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/fingerprint.nix
    ../../modules/hardware/gpu-hybrid.nix
#   ../../modules/hardware/gpu-nvidia.nix
#   ../../modules/hardware/gpu-amd.nix

    ../../modules/system/auth.nix
    ../../modules/system/boot.nix
    ../../modules/system/common.nix
    ../../modules/system/localization.nix
    ../../modules/system/memory.nix

    ../../modules/desktop/fonts.nix
#   ../../modules/desktop/hyprland.nix
    ../../modules/desktop/kde.nix

    ../../modules/networking/nfs-shares.nix
    ../../modules/networking/nfs-torrents.nix
    ../../modules/networking/tailscale.nix

    ../../modules/apps/core.nix
#   ../../modules/apps/steam.nix

#   ../../modules/services/libvirt.nix
    ../../modules/services/hp-officejet-pro-8715.nix
#   ../../modules/services/sunshine.nix
    ../../modules/services/waydroid.nix
  ];

  # Memory
  boot.kernel.sysctl."vm.swappiness" = 60;

  # Networking
  networking.hostName = "krugerrand";

  # Users
  users.users.zp = {
    isNormalUser = true;
    description = "zp";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "render"
      "input"
    ];
  };

  # Libinput - disabled because kde overrides it
#  services.libinput.enable = true;
#  services.libinput.touchpad.naturalScrolling = true;
#  services.libinput.mouse.naturalScrolling = true;

  # System packages
  environment.systemPackages = with pkgs; [

  ];

  # System state version
  system.stateVersion = "25.11";
}
