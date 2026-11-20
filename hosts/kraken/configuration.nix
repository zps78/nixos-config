# ../../hosts/kraken/configuration.nix
#
# kraken - the home NAS + game-streaming server, rebuilt on krieger's old
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
  # LAN addressing. lanIp is TEMPORARY until the old Unraid karma is
  # retired (NAS plan phase 6): then lanIp -> .5. (The name stays kraken;
  # it was "karma-n5" until 2026-11-20.)
  hostName = "kraken";
  lanIp = "192.168.1.6";         # Aquantia AQC111 (enp4s0): everything
  streamIp = "192.168.1.7";      # Intel I211 (enp5s0): Sunshine only
  gateway = "192.168.1.1";
  streamTable = "100";           # policy-routing table for streamIp
  steamUid = "1001";             # pinned below; used by the routing rule
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
  myDesktop.primaryUser                          = "zp";                       # admin: SSH, wheel, docker
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

  # Wake-on-LAN (magic packet) on both NICs, armed at every shutdown - same
  # as krieger. Set twice on purpose: the link setting (udev, applies as the
  # NIC appears) and in each NetworkManager profile below (so NM doesn't
  # reset it when it takes the device). Needs in BIOS: ErP Ready = Disabled,
  # Power On By PCI-E = Enabled. Wake from the LAN, e.g. from old karma:
  # magic packet to 50:eb:f6:ea:9b:3a (Aquantia) or :39 (Intel).
  networking.interfaces = {
    enp4s0.wakeOnLan.enable                      = true;                       # Aquantia
    enp5s0.wakeOnLan.enable                      = true;                       # Intel
  };

  # SSH on the LAN as well - a fallback for when Tailscale itself is down
  # (the fleet default is Tailscale-only). Main NIC only: the Sunshine NIC
  # stays closed. Still key-only (myServices.ssh.passwordAuth = false).
  networking.firewall.interfaces.enp4s0.allowedTCPPorts = [ 22 ];

  networking.networkmanager.ensureProfiles.profiles = {
    lan = {
      connection = { id = "lan"; type = "ethernet"; interface-name = "enp4s0"; autoconnect = true; };
      ethernet.wake-on-lan                       = 64;                         # NM flag value for "magic" (keyfiles store the number)
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
      ethernet.wake-on-lan                       = 64;                         # magic packet
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
        # Sunshine's video/audio UDP goes out from a socket bound to
        # 0.0.0.0, so "from streamIp" alone wouldn't catch it - the kernel
        # would pick the Aquantia and .6. Everything the steam user sends to
        # the LAN uses this NIC instead (ahead of the Tailscale home-LAN
        # rule at 5200). Internet/tailnet traffic keeps the normal routing.
        routing-rule2                            = "priority 101 to 192.168.1.0/24 uidrange ${steamUid}-${steamUid} table ${streamTable}";
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

  # Undo net for the OS disk's real state: /home, /var, /srv/appdata
  # (rpool/safe and children). rpool/local (/, /nix, docker) is rebuildable
  # and deliberately not snapshotted. More datasets join as drives arrive.
  myStorage.snapshots = {
    enable                                       = true;
    datasets."rpool/safe".tier                   = "important";                # 24 hourly, 30 daily, 3 monthly
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
    sunshine.enable                              = true;                       # group membership auto-follows via modules/services/sunshine.nix
    sunshine.interfaces                          = [ "enp5s0" ];               # Intel NIC only (+ tailscale0, trusted fleet-wide)
    waydroid.enable                              = false;
  };

  myFeatures = {
    steam.enable                                 = true;                       # Steam itself; launched in gamescope on demand (below)
  };

  ############################################################
  # Game streaming - headless, on demand
  ############################################################
  #
  # Moonlight: add the host by streamIp (.7), not by discovery - Sunshine's
  # ports are only open on the Intel NIC. Pick "Steam Big Picture": Steam
  # starts in gamescope on the dummy plug (a few seconds), and stops 3 min
  # after the last disconnect. See modules/desktop/steam-on-demand.nix.
  # Sunshine web UI (first-time login/pairing): https://${streamIp}:47990

  myDesktop.steamOnDemand = {
    enable                                       = true;
    output                                       = "HDMI-A-1";                 # dummy plug on the 4060 Ti (DP-2 = console monitor)
    width                                        = 1920;
    height                                       = 1080;
    refresh                                      = 60;
    renderDevice                                 = "/dev/dri/by-path/pci-0000:0b:00.0-render"; # 4060 Ti - stays put when the T1000 arrives
  };

  # Sunshine's web UI rejects requests from origins it doesn't know (CSRF
  # protection) - list every URL it is opened by: the Sunshine NIC and the
  # Tailscale name. (krieger had the same error; there it was hand-edited.)
  services.sunshine.settings.csrf_allowed_origins = builtins.concatStringsSep "," [
    "https://${streamIp}:47990"
    "https://${hostName}:47990"
  ];

  ############################################################
  # Web UIs - day-to-day operation (phase 0c)
  ############################################################
  #
  # All native NixOS services, LAN NIC + Tailscale only (never the Sunshine
  # NIC). Operate here, configure in the repo. Links use lanIp, which also
  # works away from home through the tailnet's home-subnet route.
  #   Cockpit  https://<lanIp>:9090   (zp's password; + ZFS, Files)
  #   Scrutiny http://<lanIp>:8087    (SMART health)
  #   Beszel   http://<lanIp>:8090    (metrics; admin account on first visit)
  #   Homepage http://<lanIp>:8082    (start page)
  #   wol-web  http://<lanIp>:8089    (one-click wake: /wake/<name>)

  myServices.cockpit = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
    origins                                      = [ "https://${lanIp}:9090" "https://${hostName}:9090" ];
  };

  myServices.scrutiny = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
  };

  myServices.beszel = {
    hub.enable                                   = true;
    hub.interfaces                               = [ "enp4s0" ];
    agentKey                                     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKJPfX6Upo7KwsaYYueltDi8mYb/MdUKVfm4TcpLzkP"; # hub's public key ("Add system"; system entry: 127.0.0.1:45876)
  };

  myServices.homepage = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
    hosts                                        = [ lanIp hostName ];
  };

  # Replaces GPTWOL on the Unraid karma (whose /wake needs a login, so a
  # Homepage tile couldn't wake anything). Sent from the LAN NIC.
  myServices.wolWeb = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
    sourceAddress                                = lanIp;
    machines = {
      kimi                                       = "98:fa:9b:01:58:9b";   # eno2
      karma-unraid                               = "6c:1f:f7:29:b5:4d";   # old karma eth0 (WoL g)
    };
  };

  services.homepage-dashboard = {
    settings = {
      title                                      = hostName;
      headerStyle                                = "clean";
      layout.System = { style = "row"; columns = 4; };
    };
    widgets = [
      # Disk "/" only: every rpool dataset shares the pool's free space, and
      # Homepage's sandbox (ProtectHome) can't see /home anyway.
      { resources = { cpu = true; memory = true; disk = [ "/" ]; cputemp = true; uptime = true; }; }
    ];
    services = [
      {
        System = [
          { Cockpit  = { href = "https://${lanIp}:9090";    icon = "cockpit.png";  description = "System, logs, services, ZFS, files"; }; }
          { Scrutiny = { href = "http://${lanIp}:8087";     icon = "scrutiny.png"; description = "Disk health (SMART)"; }; }
          { Beszel   = { href = "http://${lanIp}:8090";     icon = "beszel.png";   description = "Metrics and alerts"; }; }
          { Sunshine = { href = "https://${streamIp}:47990"; icon = "sunshine.png"; description = "Game streaming (pairing)"; }; }
        ];
      }
      {
        Wake = [
          { kimi           = { href = "http://${lanIp}:8089/wake/kimi";         icon = "nixos.png";  description = "Wake-on-LAN";  ping = "100.101.102.34"; }; }
          { "karma-unraid" = { href = "http://${lanIp}:8089/wake/karma-unraid"; icon = "unraid.png"; description = "Wake-on-LAN (old karma)"; ping = "192.168.1.5"; }; }
        ];
      }
    ];
  };

  ############################################################
  # Users
  ############################################################
  #
  # zp    - admin: SSH (fleet keys), wheel, docker. Lean home profile
  #         (home/profiles/server.nix). Password from agenix
  #         (secrets/zp-password.age), the same one on every host.
  # steam - Sunshine/Steam/gamescope. Unprivileged: no wheel, no docker,
  #         no password. Same role as on krieger.
  # media - UID 99 / GID 100 ("users"), matching Unraid's nobody:users.
  #         Every file on the array is owned 99:100 and the containers run
  #         with PUID=99 PGID=100, so nothing is re-owned in the move.
  #         (NixOS's own "nobody" is 65534 - deliberately not reused.)

  age.secrets.zp-password.file                   = ../../secrets/zp-password.age;

  users.users.zp = {
    isNormalUser                                 = true;
    description                                  = "zp";
    hashedPasswordFile                           = config.age.secrets.zp-password.path;
    extraGroups = [
                                                   "wheel"
                                                   "networkmanager"
                                                   "users"
    ];
  };

  users.users.steam = {
    isNormalUser                                 = true;
    uid                                          = 1001;                       # pinned: routing rule + unit ordering use it (= what the install assigned)
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
  # 0b  (done, above) Steam library on the SA500 once it moves over.
  # 0c  Web UI: Cockpit (+ zfs/files/machines plugins), Scrutiny, Beszel,
  #     Homepage, Komodo.
  # 1+  ssd-home -> Steam library; Immich/personal NVMe mirror; services;
  #     the array (disk1..5 import, mergerfs /mnt/user, SnapRAID), sanoid.
  # 6   Cutover: lanIp .5, advertiseRoutes (take over from the Unraid
  #     karma), retire the Unraid karma.

  # System state version - the release this host is first installed with.
  system.stateVersion                            = "26.11";
}
