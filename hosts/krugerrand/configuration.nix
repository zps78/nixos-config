# ../../hosts/krugerrand/configuration.nix
{ config, pkgs, lib, ... }:

{
  # Import modules
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware

    ../../modules/networking/core.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/wifi.nix

    ../../modules/shares

    ../../modules/services

    ../../modules/system

    ../../modules/desktop

    ../../modules/features

    ../../modules/apps/android.nix

  ];

  # Memory
  boot.kernel.sysctl."vm.swappiness"             = 60;

  # Networking
  networking.hostName                            = "krugerrand";
  networking.interfaces = {                                          # set WOL for wired interfaces
#   enp4s0.wakeOnLan.enable                      = true;             # atlantis nic
#   enp5s0.wakeOnLan.enable                      = true;             # intel nic
  };

  myDesktop.stack                                = "kde";            # choose from: "gnome" "hyprland" "kde" "niri"

  programs.kdeconnect.enable                     = true;

  myHardware = {
    bluetooth.enable                             = true;             # enable bluetooth on this host
    fingerprint.enable                           = true;             # enable fingerprint on this host
    gpuVendor                                    = "hybrid";         # choose from: "hybrid" "nvidia" "amd" "intel"
  };

  myServices = {
    docker.enable                                = false;
    libvirt.enable                               = false;
    hp8715.enable                                = true;
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;             # keep disabled for security
    sunshine.enable                              = false;
  };

  myShares = {
    nfs-backup.enable                            = true;
    nfs-home.enable                              = true;
    nfs-media.enable                             = true;
    nfs-paperless.enable                         = true;
    nfs-torrents.enable                          = true;
    nfs-trading.enable                           = true;
  };

  myFeatures = {
    data-rescue.enable                           = false;
    steam.enable                                 = false;
    wine.enable                                  = true;
  };

  # Users
  users.users.zp = {
    isNormalUser                                 = true;
    description                                  = "zp";
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "audio"
                                                   "video"
                                                   "render"
#                                                  "input"           # enable with sunshine
#                                                  "libvirtd"        # enable with libvirt
#                                                  "docker"          # enable with docker
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable                                       = false;
    user                                         = "zp";
  };

  # Prevent idle suspend (desktop / remote / gaming stability)
  services.logind.settings.Login = {
#   IdleAction                                   = "ignore";
#   IdleActionSec                                = "0";
    HandleLidSwitch                              = "suspend";
    HandleLidSwitchExternalPower                 = "suspend";
#   HandleLidSwitchDocked                        = "ignore";
  };

  # Libinput - disabled because kde overrides it
# services.libinput.enable                       = true;
# services.libinput.touchpad.naturalScrolling    = true;
# services.libinput.mouse.naturalScrolling       = true;

  # System packages
  environment.systemPackages                     = with pkgs; [
    #
  ];

  # System state version
  system.stateVersion                            = "25.11";
}
