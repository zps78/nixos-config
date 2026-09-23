# ../../hosts/krieger/configuration.nix
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
  networking.hostName                            = "krieger";
  networking.interfaces = {                                                    # set WOL for wired interfaces
    enp4s0.wakeOnLan.enable                      = true;                       # atlantis nic
    enp5s0.wakeOnLan.enable                      = true;                       # intel nic
  };

  # enp4s0 ("Atlantis") is a Marvell/Aquantia AQC111 5GbE NIC (atlantic
  # driver) - previously unusable for Sunshine streaming. This chip has
  # a well-documented, longstanding Linux driver quirk: the kernel's own
  # docs call its GRO implementation "suspect", and the hardware
  # mis-marks some packets with a 0xFFFF checksum as invalid, which the
  # driver has to paper over. Multiple independent users (TrueNAS,
  # TerraMaster, Arch, Ubuntu/QNAP forums) report drops/asymmetric
  # throughput on this exact chip family. Sunshine leans on UDP for the
  # actual video stream, which is exactly what a checksum/GRO bug would
  # silently corrupt while TCP traffic mostly looks fine - matching what
  # was observed. Mitigation: disable the specific hardware offloads
  # implicated (GRO/LRO/checksum/TSO/GSO), forcing the software stack to
  # handle them instead - costs some CPU, negligible on this system.
  # Not guaranteed (other users report mixed results even after this),
  # but the standard first thing to try for a chip with acknowledged
  # driver bugs. `|| true` per line since not every offload name may be
  # supported - untested, no cable currently plugged into this port.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "tune-atlantic-nic" ''
        [ "$1" = "enp4s0" ] || exit 0
        [ "$2" = "up" ] || exit 0
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 gro off || true
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 lro off || true
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 tso off || true
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 gso off || true
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 rx off || true
        ${pkgs.ethtool}/bin/ethtool -K enp4s0 tx off || true
        logger -t tune-atlantic-nic "applied offload workarounds to enp4s0"
      '';
    }
  ];

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "bb";
  myDesktop.idle.enable                          = false;                      # workstation: no idle lock/suspend (sunshine, renders)

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = false;                      # enable fingerprint on this host
    wwan.enable                                  = false;                      # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "pt";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "us";                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "nvidia";                   # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 128;                        # this host's actual installed RAM (GB)
  };

  myNetwork = {
    tailscale.enable                             = true;
    wifi.enable                                  = false;
  };

  myServices = {
    battery.enable                               = false;                      # battery support
    battery.tlp.enable                           = false;                      # TLP: low-power profile and no turbo on battery
    brother-ads-4300n.enable                     = true;                       # Brother ADS-4300N network document scanner
    brother-hl-l8230cdw.enable                   = true;                       # Brother HL-L8230CDW network color laser printer
    docker.enable                                = true;                       # group membership auto-follows via modules/services/docker.nix
    libvirt.enable                               = false;                      # group membership auto-follows via modules/services/libvirt.nix
    ssh.enable                                   = true;
    ssh.passwordAuth                             = false;                      # keep disabled for security
    ssh.authorizedKeys                           = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0omZkhZ//fafpUbFHlcFQyKY8UHIbaCzbD8PAkBsMv kuro-fleet-access"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsHK3x6UPpNqhnV0t+MMdMb1iuy1xDLBfFk1UL4TMa9 krugerrand-fleet-access"
    ];
    sunshine.enable                              = true;                       # group membership auto-follows via modules/services/sunshine.nix
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
    claude-desktop.enable                        = false;                      # Anthropic's Claude Desktop app
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
