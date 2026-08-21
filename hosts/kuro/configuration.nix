# ../../hosts/kuro/configuration.nix
{ pkgs, ... }:

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
  boot.kernel.sysctl."vm.swappiness"             = 60;

  # Networking
  networking.hostName                            = "kuro";
  networking.interfaces = {                                          # set WOL for wired interfaces
#   enp4s0.wakeOnLan.enable                      = true;             # atlantis nic
#   enp5s0.wakeOnLan.enable                      = true;             # intel nic
  };

  myDesktop.stack                                = "niri";           # choose from: "gnome" "hyprland" "kde" "niri"

  myHardware = {
    bluetooth.enable                             = true;             # enable bluetooth on this host
    fingerprint.enable                           = true;             # enable fingerprint on this host
    wwan.enable                                  = true;             # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "gb";             # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "pt";             # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "intel";          # choose from: "hybrid" "nvidia" "amd" "intel"
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = true;
  };

  myServices = {
    battery.enable                               = true;             # battery support
    brother-ads-4300n.enable                     = true;             # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;             # Brother HL-L8230CDW network color laser printer
    docker.enable                                = false;            # remmeber to add user to group docker below
    libvirt.enable                               = false;            # remmeber to add user to group libvirtd below
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;             # keep disabled for security
    sunshine.enable                              = false;            # remmeber to add user to group input below
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
    kde-connect.enable                           = true;
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
#                                                  "input"           # enable for sunshine
#                                                  "libvirtd"        # enable for libvirt
#                                                  "docker"          # enable for docker
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
#  environment.systemPackages                     = with pkgs; [
#
#  ];

  # System state version
  system.stateVersion                            = "25.11";
}
