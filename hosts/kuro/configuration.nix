# ../../hosts/kuro/configuration.nix
{ pkgs, ... }:

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
  networking.hostName                            = "kuro";
  networking.interfaces = {                                                    # set WOL for wired interfaces
#   enp4s0.wakeOnLan.enable                      = true;                       # atlantis nic
#   enp5s0.wakeOnLan.enable                      = true;                       # intel nic
  };

  # Fleet SSH access - dedicated key for reaching the rest of the fleet
  # (kepler/kimi/krugerrand/krieger/karma). See home/users/zp.nix for
  # the SSH client config that uses this, and secrets/secrets.nix for
  # recipients.
  age.secrets.kuro-fleet-key = {
    file  = ../../secrets/kuro-fleet-key.age;
    owner = "zp";
    mode  = "0400";
  };

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "zp";
  myDesktop.idle.enable                          = true;                       # laptop

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = true;                       # enable fingerprint on this host
    wwan.enable                                  = true;                       # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "gb";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "pt";                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "intel";                    # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 32;                         # this host's actual installed RAM (GB)
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = true;
  };

  myServices = {
    battery.enable                               = true;                       # battery support
    battery.tlp.enable                           = true;                       # TLP: low-power profile and no turbo on battery
    battery.tlp.usbDenylist                      = [ "06cb:00bd" "8087:0033" ];  # fingerprint reader, Bluetooth
    brother-ads-4300n.enable                     = true;                       # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;                       # Brother HL-L8230CDW network color laser printer
    docker.enable                                = false;                      # group membership auto-follows via modules/services/docker.nix
    libvirt.enable                               = false;                      # group membership auto-follows via modules/services/libvirt.nix
    ssh.enable                                   = true;
    ssh.passwordAuth                             = false;                      # keep disabled for security
    ssh.authorizedKeys                           = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsHK3x6UPpNqhnV0t+MMdMb1iuy1xDLBfFk1UL4TMa9 krugerrand-fleet-access"
    ];
    sunshine.enable                              = false;                      # group membership auto-follows via modules/services/sunshine.nix
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
    claude-desktop.enable                        = true;                       # Anthropic's Claude Desktop app
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

  # Libinput - unused on niri (its own input.kdl handles this); would apply under kde/gnome
# services.libinput.enable                       = true;
# services.libinput.touchpad.naturalScrolling    = true;
# services.libinput.mouse.naturalScrolling       = true;

  # System packages
# environment.systemPackages                     = with pkgs; [
#
# ];

  # System state version
  system.stateVersion                            = "25.11";
}
