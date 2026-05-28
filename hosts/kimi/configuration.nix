# ../../hosts/kimi/configuration.nix
{ config, pkgs, lib, ... }:

{
#  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/fingerprint.nix

#   ../../modules/hardware/gpu-hybrid.nix
    ../../modules/hardware/gpu-intel.nix
#   ../../modules/hardware/gpu-nvidia.nix
#   ../../modules/hardware/gpu-amd.nix

    ../../modules/system/auth.nix
    ../../modules/system/boot.nix
    ../../modules/system/common.nix
    ../../modules/system/localization.nix
    ../../modules/system/memory.nix

    ../../modules/desktop/fonts.nix

#   ../../modules/desktop/gnome.nix
#   ../../modules/desktop/hyprland.nix
    ../../modules/desktop/kde.nix

    ../../modules/networking/core.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/wifi.nix

#   ../../modules/networking/mounts/nfs-backup.nix
#   ../../modules/networking/mounts/nfs-home.nix
#   ../../modules/networking/mounts/nfs-media.nix
#   ../../modules/networking/mounts/nfs-paperless.nix
#   ../../modules/networking/mounts/nfs-torrents.nix
#   ../../modules/networking/mounts/nfs-trading.nix

    ../../modules/apps/android.nix
    ../../modules/apps/core.nix
#   ../../modules/apps/steam.nix
    ../../modules/apps/wine.nix

    ../../modules/services/discovery.nix
#   ../../modules/services/docker.nix
#   ../../modules/services/libvirt.nix
    ../../modules/services/hp-officejet-pro-8715.nix
    ../../modules/services/rustdesk.nix
    ../../modules/services/ssh.nix
    ../../modules/services/sunshine.nix
#   ../../modules/services/waydroid.nix
  ];

  # Memory
  boot.kernel.sysctl."vm.swappiness" = 100;

  # Networking
  networking.hostName = "kimi";
  networking.interfaces.eno2 = {
    wakeOnLan.enable = true;   # -> only for ethernet wired hosts
  };

  # enable fingerprint on this host
  mySystem.hasFingerprint = false;

  my.services.ssh = {
    enable = true;
    passwordAuth = true;   # keep disabled for security
  };

  my.services.sunshine = {
    enable = true;
    gpuVendor = "intel"; # choose from: "none" "nvidia" "amd" "intel"
  };

  # Users
  users.users.gt = {
    isNormalUser = true;
    description = "gt";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "render"
      "input"      # -> enable with sunshine
#     "libvirtd"   # -> enable with libvirt
#     "docker"     # -> enable with docker
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable = true;
    user = "gt";
  };

  # Prevent idle suspend (desktop / remote / gaming stability)
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
#   HandleLidSwitch = "suspend";
#   HandleLidSwitchExternalPower = "suspend";
#   HandleLidSwitchDocked = "ignore";
  };

  # Libinput - disabled because kde overrides it
#  services.libinput.enable = true;
#  services.libinput.touchpad.naturalScrolling = true;
#  services.libinput.mouse.naturalScrolling = true;

  # System packages
  environment.systemPackages = with pkgs; [
    #
  ];

  # System state version
  system.stateVersion = "25.11";
}
