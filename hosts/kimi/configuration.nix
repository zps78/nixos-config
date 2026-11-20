# ../../hosts/kimi/configuration.nix
{ config, ... }:

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
    eno2.wakeOnLan.enable                        = true;                       # kimi's only wired nic
  };

  # Fixed LAN address, same last octet as the tailnet: 192.168.1.50 /
  # 100.101.102.50 (kraken is .10). DNS as the router's DHCP hands out
  # (Pi-hole on the Unraid karma, AdGuard as fallback) - revisit at the
  # phase-6 cutover. no-auto-default: no stray DHCP "Wired connection N".
  networking.networkmanager.settings.main.no-auto-default = "*";
  networking.networkmanager.ensureProfiles.profiles.lan = {
    connection = { id = "lan"; type = "ethernet"; interface-name = "eno2"; autoconnect = true; autoconnect-priority = 10; };
    ethernet.wake-on-lan                         = 64;                         # magic packet (NM's keyfile value)
    ipv4 = {
      method                                     = "manual";
      address1                                   = "192.168.1.50/24,192.168.1.1";
      dns                                        = "192.168.1.5;94.140.14.14;";
    };
    ipv6.method                                  = "auto";
  };

  # Outbound key to reach kraken as a distributed-build client (nix-daemon
  # runs as root, so owned by root here rather than the zp-owned pattern
  # kuro/krugerrand use - there's no interactive admin use for this one).
  # See modules/system/remote-builders.nix and secrets/secrets.nix.
  age.secrets.kimi-fleet-key = {
    file  = ../../secrets/kimi-fleet-key.age;
    owner = "root";
    mode  = "0400";
  };

  myDesktop.stack                                = "niri";                     # choose from: "gnome" "kde" "niri"
  myDesktop.primaryUser                          = "zp";                       # admin: SSH, wheel - no autologin
  myDesktop.sessionUser                          = "gt";                       # autologin + Sunshine (niri session owner)
  myDesktop.idle.enable                          = false;                      # headless appliance (dummy plug, SimHub via Wine) - never idle/suspend

  myHardware = {
    bluetooth.enable                             = true;                       # enable bluetooth on this host
    fingerprint.enable                           = false;                      # enable fingerprint on this host
    memtest.enable                               = false;                      # MemTest86+ entry in the systemd-boot menu
    wwan.enable                                  = false;                      # enable wwan mhi driver and install modem manager

    keyboard.layout                              = "pt";                       # keyboard layout for X11/Wayland and console ("pt" "us" "gb")
    keyboard.secondary.layout                    = "us";                       # secondary keyboard layout (not available on tty)
    gpuVendor                                    = "intel";                    # choose from: "hybrid" "nvidia" "amd" "intel"
    ramGB                                        = 16;                         # this host's actual installed RAM (GB)
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
    docker.enable                                = false;                      # group membership auto-follows via modules/services/docker.nix
    aiStack.enable                               = false;                      # Ollama + Open WebUI + ComfyUI, GPU-accelerated (docker)
    libvirt.enable                               = false;                      # group membership auto-follows via modules/services/libvirt.nix
    ssh.enable                                   = true;
    ssh.passwordAuth                             = false;                      # keep disabled for security
    ssh.authorizedKeys                           = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0omZkhZ//fafpUbFHlcFQyKY8UHIbaCzbD8PAkBsMv kuro-fleet-access"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsHK3x6UPpNqhnV0t+MMdMb1iuy1xDLBfFk1UL4TMa9 krugerrand-fleet-access"
    ];
    sunshine.enable                              = true;                       # group membership auto-follows via modules/services/sunshine.nix
    waydroid.enable                              = false;
    waydroid.extras                              = [ "microg" "widevine" "libhoudini" ]; # Intel CPU -> libhoudini, not libndk
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
    android.enable                               = false;                      # ADB, scrcpy, APK tools
    brave-policies.enable                        = true;                       # Brave managed policy JSON: block Google GSI, no translate offer, no password save, no telemetry
    citizen-card.enable                          = false;                      # Portuguese Citizen Card eID (reader + Autenticacao.Gov)
    claude-desktop.enable                        = false;                      # Anthropic's Claude Desktop app
    data-rescue.enable                           = false;
    kde-connect.enable                           = false;
    proxmark3.enable                             = false;                      # Proxmark3 RFID/NFC tooling (Iceman client, udev rule)
    remoteBuilder.enable                         = true;                       # offload big builds to kraken (always-on 5950X); local fallback
    steam.enable                                 = false;
    wine.enable                                  = true;
  };

  # Sunshine settings, declared here: once any setting is set (the module's
  # capture = "kms"), NixOS hands Sunshine its own config file and gt's
  # hand-edited ~/.config/sunshine/sunshine.conf is no longer read.
  # csrf_allowed_origins: every URL the web UI is opened by, or its actions
  # fail with "CSRF Protection Error". No output_name: with KMS capture
  # Sunshine numbers displays (HDMI-A-2 is "Monitor 0") and kimi has one.
  services.sunshine.settings = {
    csrf_allowed_origins                         = "https://192.168.1.50:47990,https://kimi:47990";
    encoder                                      = "vaapi";                    # Intel UHD 630
    key_rightalt_to_key_win                      = "enabled";
    address_family                               = "both";
    min_log_level                                = "info";                     # sessions, input mode, errors (warning hid them)
  };

  # Users
  #
  # zp - admin: SSH (fleet keys via myServices.ssh), wheel. Password from
  #      agenix (secrets/zp-password.age), the same one on every host.
  # gt - the autologin/niri/Sunshine session. Unprivileged: no wheel and
  #      no fleet keys (Tailscale SSH still follows the tailnet's SSH
  #      policy, but gt can't sudo). Admin work is zp's.
  age.secrets.zp-password.file                   = ../../secrets/zp-password.age;

  users.users.zp = {
    isNormalUser                                 = true;
    description                                  = "zp";
    hashedPasswordFile                           = config.age.secrets.zp-password.path;
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
    ];
  };

  users.users.gt = {
    isNormalUser                                 = true;
    description                                  = "gt";
    extraGroups = [
                                                   "networkmanager"
                                                   "audio"
                                                   "video"
                                                   "render"
    ];
  };

  # Display manager - auto login
  services.displayManager.autoLogin = {
    enable                                       = true;
    user                                         = config.myDesktop.sessionUser;
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
# environment.systemPackages                     = with pkgs; [
#
# ];

  # System state version
  system.stateVersion                            = "25.11";
}
