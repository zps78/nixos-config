# ../../hosts/krieger/configuration.nix
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
  networking.hostName                            = "krieger";
  networking.interfaces = {                                                    # set WOL for wired interfaces
    enp4s0.wakeOnLan.enable                      = true;                       # atlantis nic
    enp5s0.wakeOnLan.enable                      = true;                       # intel nic
  };

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "bb";
  myDesktop.idle.enable                          = false;                      # workstation: no idle lock/suspend (sunshine, renders)

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = false;                      # enable fingerprint on this host
    wwan.enable                                  = false;                      # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "us";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "pt";                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "nvidia";                   # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 128;                        # this host's actual installed RAM (GB)
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = false;
  };

  myServices = {
    battery.enable                               = false;                      # battery support
    brother-ads-4300n.enable                     = true;                       # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;                       # Brother HL-L8230CDW network color laser printer
    docker.enable                                = true;                       # remmeber to add user to group docker below
    libvirt.enable                               = false;                      # remmeber to add user to group libvirtd below
    ssh.enable                                   = true;
    ssh.passwordAuth                             = true;                       # keep disabled for security
    sunshine.enable                              = true;                       # remmeber to add user to group input below
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
    android.enable                               = true;                       # ADB, scrcpy, APK tools
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
                                                   "input"                     # enable for sunshine
                                                   "libvirtd"                  # enable for libvirt
                                                   "docker"                    # enable for docker
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
