# ../../hosts/krieger/configuration.nix
{ config, pkgs, lib, ... }:

{
  # Import modules
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop
    ../../modules/features
    ../../modules/hardware
    ../../modules/networking
    ../../modules/shares
    ../../modules/services
    ../../modules/system

    ../../modules/apps/android.nix
  ];

  # Memory
  boot.kernel.sysctl."vm.swappiness"             = 10;

  # Networking
  networking.hostName                            = "krieger";
  networking.interfaces = {                                          # set WOL for wired interfaces
    enp4s0.wakeOnLan.enable                      = true;             # atlantis nic
    enp5s0.wakeOnLan.enable                      = true;             # intel nic
  };

  myDesktop.stack                                = "kde";            # choose from: "gnome" "hyprland" "kde" "niri"

  myHardware = {
    bluetooth.enable                             = true;             # enable bluetooth on this host
    fingerprint.enable                           = false;            # enable fingerprint on this host
    keyboard.layout                              = "pt";             # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    gpuVendor                                    = "nvidia";         # choose from: "hybrid" "nvidia" "amd" "intel"
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = false;
  };

  myServices = {
    brother-ads-4300n.enable                     = true;             # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;             # Brother HL-L8230CDW network color laser printer
    docker.enable                                = true;             # add user to group docker below
    libvirt.enable                               = false;            # add user to group LIBVIRT below
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;             # keep disabled for security
    sunshine.enable                              = true;             # add user to group input below
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
    data-rescue.enable                           = true;
    kde-connect.enable                           = false;
    steam.enable                                 = true;
    wine.enable                                  = true;
  };

  # Users
  users.users.bb = {
    isNormalUser                                 = true;
    description                                  = "bb";
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "audio"
                                                   "video"
                                                   "render"
                                                   "input"           # enable with sunshine
#                                                  "libvirtd"        # enable with libvirt
                                                   "docker"          # enable with docker
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable                                       = true;
    user                                         = "bb";
  };

  # Prevent idle suspend (desktop / remote / gaming stability)
  services.logind.settings.Login = {
    IdleAction                                   = "ignore";
    IdleActionSec                                = "0";
#   HandleLidSwitch                              = "suspend";
#   HandleLidSwitchExternalPower                 = "suspend";
#   HandleLidSwitchDocked                        = "ignore";
  };

  # Libinput - disabled because kde overrides it
# services.libinput.enable                       = true;
# services.libinput.touchpad.naturalScrolling    = true;
# services.libinput.mouse.naturalScrolling       = true;

  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (old: {
        doCheck = false;
      });
    })
  ];

  # System packages
  environment.systemPackages                     = with pkgs; [
    #
  ];

  # System state version
  system.stateVersion                            = "25.11";
}
