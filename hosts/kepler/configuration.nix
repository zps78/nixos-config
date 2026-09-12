# ../../hosts/kepler/configuration.nix
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
  networking.hostName                            = "kepler";
  networking.interfaces = {                                                    # set WOL for wired interfaces
#   enp4s0.wakeOnLan.enable                      = true;                       # atlantis nic
#   enp5s0.wakeOnLan.enable                      = true;                       # intel nic
  };

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "sc";

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = true;                       # enable fingerprint on this host
    wwan.enable                                  = false;                      # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "pt";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = null;                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "amd";                      # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 16;                         # this host's actual installed RAM (GB)
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = true;
  };

  myServices = {
    battery.enable                               = true;                       # battery support
    brother-ads-4300n.enable                     = true;                       # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;                       # Brother HL-L8230CDW network color laser printer
    docker.enable                                = false;                      # group membership auto-follows via modules/services/docker.nix
    libvirt.enable                               = false;                      # group membership auto-follows via modules/services/libvirt.nix
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;                       # keep disabled for security
    sunshine.enable                              = false;                      # group membership auto-follows via modules/services/sunshine.nix
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
    kde-connect.enable                           = true;
    steam.enable                                 = true;
    wine.enable                                  = false;
  };

  # Users
  users.users.sc = {
    isNormalUser                                 = true;
    description                                  = "sc";
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "audio"
                                                   "video"
                                                   "render"
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable                                       = false;
    user                                         = "sc";
  };

  # Prevent idle suspend (desktop / remote / gaming stability)
  services.logind.settings.Login = {
#   IdleAction                                   = "ignore";
#   IdleActionSec                                = "0";
    HandleLidSwitch                              = "suspend";
    HandleLidSwitchExternalPower                 = "suspend";
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
