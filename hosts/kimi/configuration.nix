# ../../hosts/kimi/configuration.nix
{ ... }:

{
  # Import modules
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop
    ../../modules/apps-system
    ../../modules/hardware
    ../../modules/networking
    ../../modules/shares
    ../../modules/services
    ../../modules/system
  ];

  # Networking
  networking.hostName                            = "kimi";
  networking.interfaces = {                                                    # set WOL for wired interfaces
    enp4s0.wakeOnLan.enable                      = true;                       # atlantis nic
    enp5s0.wakeOnLan.enable                      = true;                       # intel nic
  };

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "gt";
  myDesktop.idle.enable                          = false;                      # headless appliance (dummy plug, SimHub via Wine) - never idle/suspend

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = false;                      # enable fingerprint on this host
    wwan.enable                                  = false;                      # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "us";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "pt";                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "intel";                    # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 16;                         # this host's actual installed RAM (GB)
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = false;
  };

  myServices = {
    battery.enable                               = false;                      # battery support
    brother-ads-4300n.enable                     = true;                       # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;                       # Brother HL-L8230CDW network color laser printer
    docker.enable                                = false;                      # remmeber to add user to group docker below
    libvirt.enable                               = false;                      # remmeber to add user to group libvirtd below
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;                       # keep disabled for security
    sunshine.enable                              = true;                       # remmeber to add user to group input below
  };

  myShares = {
    nfs-backup.enable                            = false;
    nfs-home.enable                              = false;
    nfs-media.enable                             = false;
    nfs-paperless.enable                         = false;
    nfs-torrents.enable                          = true;
    nfs-trading.enable                           = false;
  };

  myFeatures = {
    android.enable                               = true;                       # ADB, scrcpy, APK tools
    data-rescue.enable                           = false;
    kde-connect.enable                           = false;
    steam.enable                                 = false;
    wine.enable                                  = true;
  };

  # Users
  users.users.gt = {
    isNormalUser                                 = true;
    description                                  = "gt";
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "audio"
                                                   "video"
                                                   "render"
                                                   "input"                     # enable for sunshine
#                                                  "libvirtd"                  # enable for libvirt
#                                                  "docker"                    # enable for docker
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable                                       = true;
    user                                         = "gt";
  };

  # Prevent idle suspend (desktop / remote / gaming stability)
  services.logind.settings.Login = {
    IdleAction                                   = "ignore";
    IdleActionSec                                = "0";
#   HandleLidSwitch                              = "suspend";
#   HandleLidSwitchExternalPower                 = "suspend";
#   HandleLidSwitchDocked                        = "ignore";
  };

  # Libinput - unused on niri (its own input.kdl handles this); would apply under kde/gnome
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
