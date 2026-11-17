# ../../hosts/karma/configuration.nix
#
# karma - the home NAS + game-streaming server, rebuilt on krieger's old
# internals (Crosshair VIII Formula, 5950X, RTX 4060 Ti + T1000) in a
# Jonsbo N5. Replaces the Unraid karma; see the NAS plan for the phases.
#
# Headless: no desktop, no greeter, no autologin - the console is a plain
# getty (tty1) for when SSH is unreachable. Games are streamed with
# Sunshine; Steam/gamescope start on demand when Moonlight connects.
#
# STATUS: phase 0 (base system). Storage (mergerfs/SnapRAID/sanoid,
# NFS/SMB), containers and the on-demand Sunshine session come in later
# phases - see the TODO block at the end.
{ config, pkgs, ... }:

let
  # LAN addressing. TEMPORARY until the old Unraid karma is retired
  # (NAS plan phase 6): then hostName -> "karma" and lanIp -> .5.
  hostName = "karma-n5";
  lanIp = "192.168.1.6";         # Aquantia AQC111 (enp4s0): everything
  streamIp = "192.168.1.7";      # Intel I211 (enp5s0): Sunshine only
  gateway = "192.168.1.1";
  streamTable = "100";           # policy-routing table for streamIp
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop          # options only here: myDesktop.stack = "none"
    ../../modules/apps-system
    ../../modules/hardware
    ../../modules/networking
    ../../modules/services
    ../../modules/storage
    ../../modules/system
  ];

  ############################################################
  # Identity
  ############################################################

  networking.hostName                            = hostName;
  networking.hostId                              = "7d2b4492";                 # ZFS: random, fixed for this host's lifetime

  myDesktop.stack                                = "none";                     # headless
  myDesktop.primaryUser                          = "dh";                       # admin: SSH, wheel, docker
  myDesktop.sessionUser                          = "steam";                    # Sunshine/Steam session owner (unprivileged)

  ############################################################
  # Network - two NICs on the same LAN, split by role
  ############################################################
  #
  # Aquantia (enp4s0, 2.5G on the switch) carries the default route and
  # every NAS service. Intel (enp5s0, 1G) carries Sunshine only: Moonlight
  # adds this host by streamIp. Two addresses on one subnet need:
  #   - arp_ignore/arp_announce: each NIC answers ARP only for its own IP
  #     (otherwise both claim both addresses - "ARP flux");
  #   - a policy rule so replies from streamIp leave via the Intel NIC
  #     (otherwise Linux sends them out the default-route NIC);
  #   - a higher route metric on the Intel NIC so ordinary LAN traffic
  #     from lanIp keeps using the Aquantia.
  # The Aquantia's offloads stay ON here: krieger's tune-atlantic-nic
  # workaround only existed for Sunshine's UDP stream, which no longer
  # touches this NIC. Re-add it if NAS transfers misbehave.

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore"               = 1;
    "net.ipv4.conf.all.arp_announce"             = 2;
  };

  networking.networkmanager.settings.main.no-auto-default = "*";               # no stray DHCP "Wired connection N" profiles

  networking.networkmanager.ensureProfiles.profiles = {
    lan = {
      connection = { id = "lan"; type = "ethernet"; interface-name = "enp4s0"; autoconnect = true; };
      ipv4 = {
        method                                   = "manual";
        address1                                 = "${lanIp}/24,${gateway}";
        dns                                      = "${gateway};";
        route-metric                             = 100;
      };
      ipv6.method                                = "auto";
    };

    stream = {
      connection = { id = "stream"; type = "ethernet"; interface-name = "enp5s0"; autoconnect = true; };
      ipv4 = {
        method                                   = "manual";
        address1                                 = "${streamIp}/24";
        never-default                            = true;
        route-metric                             = 200;
        route1                                   = "0.0.0.0/0,${gateway}";
        route1_options                           = "table=${streamTable}";
        route2                                   = "192.168.1.0/24";
        route2_options                           = "table=${streamTable}";
        routing-rule1                            = "priority 100 from ${streamIp} table ${streamTable}";
      };
      ipv6.method                                = "disabled";                 # Sunshine stays IPv4 on this NIC
    };
  };

  ############################################################
  # Hardware
  ############################################################

  myHardware = {
    bluetooth.enable                             = false;
    fingerprint.enable                           = false;
    memtest.enable                               = true;                       # MemTest86+ in the boot menu (RAM history: NR14-2 bad, 2026-11)
    wwan.enable                                  = false;

    keyboard.layout                              = "pt";                       # console (getty) layout
    gpuVendor                                    = "nvidia";                   # RTX 4060 Ti (Sunshine/games) + T1000 (Plex/Immich)
    ramGB                                        = 64;                         # SJC5 pair while the NR14 kit is in RMA; 128 after
  };

  ############################################################
  # Storage
  ############################################################

  myStorage.zfs = {
    enable                                       = true;
    extraPools                                   = [ ];                        # phase 2: personal NVMe mirror; phase 6: disk1..disk5 (after a first manual import)
  };

  ############################################################
  # Network services
  ############################################################

  myNetwork = {
    tailscale.enable                             = true;
    tailscale.advertiseRoutes                    = [ ];                        # phase 6: [ "192.168.1.0/24" ] - old karma advertises it until then
    wifi.enable                                  = false;
  };

  myServices = {
    battery.enable                               = false;
    brother-ads-4300n.enable                     = false;
    brother-hl-l8230cdw.enable                   = false;
    docker.enable                                = true;                       # group membership auto-follows via modules/services/docker.nix
    aiStack.enable                               = false;
    libvirt.enable                               = false;                      # later: the Office VM (karma's domains share)
    ssh.enable                                   = true;
    ssh.passwordAuth                             = false;
    ssh.authorizedKeys                           = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0omZkhZ//fafpUbFHlcFQyKY8UHIbaCzbD8PAkBsMv kuro-fleet-access"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsHK3x6UPpNqhnV0t+MMdMb1iuy1xDLBfFk1UL4TMa9 krugerrand-fleet-access"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtfmTdbElBJm6tYaO//5GFJPgmx7Tt2LASqbnt3VGYR kepler-fleet-access"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/cGfUQTEWXEsxhFFyf0sZAYDQ8GNvCJUVfZ/qUr/hH kimi-fleet-access"
    ];
    sunshine.enable                              = false;                      # TODO phase 0b: headless, on-demand session (see TODO below)
    waydroid.enable                              = false;
  };

  myFeatures = {
    steam.enable                                 = true;                       # Steam itself; launched in gamescope on demand (phase 0b)
  };

  ############################################################
  # Users
  ############################################################
  #
  # dh    - admin ("dharma"): SSH (fleet keys), wheel, docker. Lean home profile
  #         (home/users/dh.nix), not krieger's workstation apps.
  # steam - Sunshine/Steam/gamescope. Unprivileged: no wheel, no docker,
  #         no password. Same role as on krieger.
  # media - UID 99 / GID 100 ("users"), matching Unraid's nobody:users.
  #         Every file on the array is owned 99:100 and the containers run
  #         with PUID=99 PGID=100, so nothing is re-owned in the move.
  #         (NixOS's own "nobody" is 65534 - deliberately not reused.)

  users.users.dh = {
    isNormalUser                                 = true;
    description                                  = "dh";
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "users"
    ];
  };

  users.users.steam = {
    isNormalUser                                 = true;
    description                                  = "Steam / Sunshine session";
    extraGroups = [
                                                   "audio"
                                                   "video"
                                                   "render"
    ];
  };

  users.users.media = {
    isSystemUser                                 = true;
    uid                                          = 99;
    group                                        = "users";
    description                                  = "Media and share file owner";
  };

  ############################################################
  # Power / console
  ############################################################

  # A server: never sleep on idle.
  services.logind.settings.Login = {
    IdleAction                                   = "ignore";
    IdleActionSec                                = "0";
  };

  ############################################################
  # TODO (next phases)
  ############################################################
  #
  # 0b  Headless on-demand gaming: steam lingering with PipeWire +
  #     Sunshine; Sunshine's prep-cmd starts a system steam-gamescope
  #     unit on its own tty (polkit lets steam start/stop only that unit),
  #     stops it ~3 min after disconnect. Sunshine ports opened only on
  #     enp5s0 (+ tailscale0). Dummy plug on the 4060 Ti.
  # 0c  Web UI: Cockpit (+ zfs/files/machines plugins), Scrutiny, Beszel,
  #     Homepage, Komodo.
  # 1+  ssd-home -> Steam library; Immich/personal NVMe mirror; services;
  #     the array (disk1..5 import, mergerfs /mnt/user, SnapRAID), sanoid.
  # 6   Cutover: hostName "karma", lanIp .5, advertiseRoutes, agenix
  #     karma-host, remote builder (modules/system/remote-builders.nix
  #     still points at krieger).

  # System state version - the release this host is first installed with.
  system.stateVersion                            = "26.11";
}
