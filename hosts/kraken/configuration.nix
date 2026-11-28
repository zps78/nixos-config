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
  # LAN addressing. Fixed hosts use the same last octet on the LAN as on
  # the tailnet: kraken is 192.168.1.10 / 100.101.102.10 (kimi .50); the
  # Sunshine NIC is the next address, .11. (Named karma-n5 until
  # 2026-11-20; LAN .6 / stream .7 until then.)
  hostName = "kraken";
  lanIp = "192.168.1.10";        # Aquantia AQC111 (enp4s0): everything
  streamIp = "192.168.1.11";     # Intel I211 (enp5s0): Sunshine only
  tailIp = "100.101.102.10";     # Tailscale (fixed in the admin console)
  gateway = "192.168.1.1";
  streamTable = "100";           # policy-routing table for streamIp
  steamUid = "1001";             # pinned below; used by the routing rule
in
{
  imports = [
    ./hardware-configuration.nix
    ./karma-services.nix           # TEMPORARY: karma's Plex + download group 1:1 (move day)
    ./array.nix                    # scratch SSD, SnapRAID parity, media scrubs
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
  myDesktop.primaryUser                          = "zp";                       # admin: SSH, wheel
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
  #
  # The NIC names are pinned to the cards' permanent MACs (a .link file per
  # NIC, which also sets Wake-on-LAN): the kernel derives enp4s0/enp5s0 from
  # the PCI address, and moving cards between slots (the N5 move) would
  # rename them - breaking the NM profiles, firewall and Sunshine NIC. These
  # replace networking.interfaces.*.wakeOnLan, whose .link files matched the
  # kernel name (and would silently stop matching after a rename).
  systemd.network.links = {
    "10-lan" = {
      matchConfig.PermanentMACAddress            = "50:eb:f6:ea:9b:3a";       # Aquantia AQC111
      linkConfig = { Name = "enp4s0"; WakeOnLan = "magic"; };
    };
    "10-stream" = {
      matchConfig.PermanentMACAddress            = "50:eb:f6:ea:9b:39";       # Intel I211
      linkConfig = { Name = "enp5s0"; WakeOnLan = "magic"; };
    };
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
        # would pick the Aquantia and lanIp. Everything the steam user sends to
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
    extraPools                                   = [ "games" "vault" ];        # + phase 2: personal NVMe mirror; phase 6: disk1..disk5 (after a first manual import)
  };

  # vault: 4x 4TB WD Red (WD40EFRX, on the ASM1166 card) as two mirrors,
  # ~7.2 TiB, created 2026-11-23. Everything non-media: home, trading,
  # backup, setup, Immich originals, and the replicas of the NVMe mirror's
  # snapshots. Media stays on the HDD array (phase 6). Datasets (legacy
  # mounts, like games/steam) get added as each piece of data moves over.

  # Undo net for the OS disk's real state: /home, /var, /srv/appdata
  # (rpool/safe and children). rpool/local (/, /nix, containers) is rebuildable
  # and deliberately not snapshotted. More datasets join as drives arrive.
  myStorage.snapshots = {
    enable                                       = true;
    datasets."rpool/safe".tier                   = "important";                # 24 hourly, 30 daily, 3 monthly
    datasets."vault/files".tier                  = "cold";                     # FileBrowser files: 30 daily, 6 monthly (no hourly HDD wake-ups)
    # data moved from karma: daily + monthly, no hourly HDD wake-ups
    datasets."vault/home".tier                   = "cold";
    datasets."vault/trading".tier                = "cold";
    datasets."vault/backup".tier                 = "cold";
    datasets."vault/setup".tier                  = "cold";
    datasets."vault/photos".tier                 = "cold";
  };

  # Game saves off the games SSD (single disk, not snapshotted) into
  # vault/gamesaves (mirrored). Checked every 6 h, but vault is only touched
  # after playing; each such backup gets its own snapshot (newest 100 kept)
  # - no sanoid hourly snapshots here, those would wake the HDDs. See
  # modules/storage/game-saves.nix.
  # Pool health/fill/last scrub as JSON for Homepage (127.0.0.1:8189).
  myStorage.statusApi.enable                     = true;

  myStorage.gameSaves = {
    enable                                       = true;
    target                                       = "/srv/gamesaves";
    dataset                                      = "vault/gamesaves";
  };

  ############################################################
  # Network services
  ############################################################

  myNetwork = {
    tailscale.enable                             = true;
    tailscale.advertiseRoutes                    = [ "192.168.1.0/24" ];       # subnet router for the home LAN (took over from karma, 2026-11-26)
    tailscale.advertiseExitNode                  = true;                       # exit node (took over from karma)
    wifi.enable                                  = false;
  };

  myServices = {
    battery.enable                               = false;
    brother-ads-4300n.enable                     = false;
    brother-hl-l8230cdw.enable                   = false;
    docker.enable                                = false;                      # containers run on Podman (virtualisation.podman, with StemDeck)
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
    media-tools.enable                           = true;                       # HandBrakeCLI (NVENC) + presets, MKVToolNix CLI, mediainfo, HDR tools
    data-rescue.enable                           = true;                       # ddrescue, testdisk/photorec, ntfs3g, btrfs, gdisk, lsscsi, ...
  };

  ############################################################
  # Game streaming - headless, on demand
  ############################################################
  #
  # Moonlight: add the host by streamIp (.7), not by discovery - Sunshine's
  # ports are only open on the Intel NIC. Pick "Steam Big Picture": Steam
  # starts in gamescope on the dummy plug (a few seconds), and stops 3 min
  # after the last disconnect. See modules/desktop/stream-apps/.
  # Sunshine web UI (first-time login/pairing): https://${streamIp}:47990

  # Stable name for the 4060 Ti's render node, by PCI vendor:device ID
  # (10de:2805) instead of its slot address - the by-path name changes when
  # the card moves to another slot (N5 move). Only NVIDIA render nodes match
  # (the boot-time simple-framebuffer has no render node).
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", ATTRS{vendor}=="0x10de", ATTRS{device}=="0x2805", SYMLINK+="dri/by-gpu/rtx4060ti-render"
  '';

  # Moonlight apps (modules/desktop/stream-apps/): one at a time on the
  # dummy plug, each in its own session, stopped after a disconnect grace.
  myDesktop.streamApps = {
    enable                                       = true;
    output                                       = "HDMI-A-1";                 # dummy plug on the 4060 Ti (DP-2 = console monitor)
    width                                        = 1920;
    height                                       = 1080;
    refresh                                      = 60;
    renderDevice                                 = "/dev/dri/by-gpu/rtx4060ti-render"; # 4060 Ti by model ID (udev rule below) - survives slot moves
    steam.enable                                 = true;                       # "Steam Big Picture": Steam in gamescope; power menu acts on the session only
    steam.idleStop                               = "10min";                    # Steam keeps running this long after a disconnect
    zen.enable                                   = true;                       # "Zen (VPN)": Zen in cage, inside the airvpn namespace
    zen.idleStop                                 = "10s";                      # ...Zen only this long (privacy)
    lutris.enable                                = true;                       # "Lutris": installers with a GUI (labwc); stays 2 h after a disconnect, longer while Wine runs
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
  #   AdGuard  http://<lanIp>:3000    (DNS filter; config in the repo only)
  #   Paperless http://<lanIp>:28981  (documents; Paperless's own logins)

  # Paperless-ngx, moved from karma's container (phase 3). Data in
  # /var/lib/paperless (rpool/safe/var - snapshotted); moves to the NVMe
  # mirror once that exists. Scanner drop folder over SMB: not yet.
  myServices.paperless = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
  };

  # SMB share for the scanner (Brother ADS-4300N, 192.168.1.101): it scans
  # straight into Paperless's consume folder as user "scanner"; Samba
  # writes the files as the paperless user, so Paperless can consume and
  # remove them. Scanner profiles: host 192.168.1.10, share "paperless",
  # no subfolder (a subfolder would become a tag). Password: agenix.
  age.secrets.samba-scanner.file                 = ../../secrets/samba-scanner-password.age;
  systemd.services.samba-users.restartTriggers   = [ (builtins.hashFile "sha256" config.age.secrets.samba-scanner.file) ]; # new password -> set at the next rebuild
  # FileBrowser Quantum: web file manager, WebDAV and share links (LAN +
  # tailnet; share links only also public via the tunnel as files.jpc.onl).
  # Files on vault/files; more sources (media, karma's data) join at the
  # big switch. Admin user zp, password from agenix.
  age.secrets.filebrowser-admin.file             = ../../secrets/filebrowser-admin.age;
  systemd.services.filebrowser-quantum.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.filebrowser-admin.file) ];
  systemd.tmpfiles.rules                         = [ "d /srv/files 2775 filebrowser users -" ];
  myServices.filebrowserQuantum = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
    adminUser                                    = "zp";
    adminPasswordFile                            = config.age.secrets.filebrowser-admin.path;
    publicUrl                                    = "https://files.jpc.onl";   # no trailing slash (Quantum adds it)
    sources                                      = [ { name = "files"; path = "/srv/files"; } ];
    # kraken look: Homepage navy + the squid's teal
    darkBackground                               = "#0e1420";
    themeColor                                   = "#20968c";
    customCss                                    = builtins.readFile ../../dotfiles/homepage/filebrowser-theme.css;
  };

  # StemDeck (moved from karma 2026-11-26): stem separation on the GPU.
  # Public as stemdeck.jpc.onl through the tunnel (route -> localhost:8010),
  # behind Cloudflare Access - StemDeck has no login of its own. Only via
  # the tunnel: it refuses plain http from other devices (needs HTTPS).
  myServices.stemdeck.enable                     = true;

  # Containers: Podman (rootful, via oci-containers), shown in Cockpit
  # (cockpit-podman). Images in /var/lib/containers = rpool/local/containers,
  # outside the snapshotted rpool/safe.
  virtualisation.podman.enable                   = true;
  virtualisation.oci-containers.backend          = "podman";

  # Cloudflare tunnel (dashboard-managed): files.jpc.onl -> FileBrowser
  # Quantum (localhost:8095), only the path ^/public/ (share pages, their
  # API and static files) - set as the route in the dashboard.
  age.secrets.cloudflare-tunnel.file             = ../../secrets/cloudflare-tunnel.age;
  systemd.services.cloudflare-tunnel.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.cloudflare-tunnel.file) ];
  myServices.cloudflareTunnel = {
    enable                                       = true;
    tokenEnvFile                                 = config.age.secrets.cloudflare-tunnel.path;
  };

  myServices.samba = {
    enable                                       = true;
    interfaces                                   = [ "enp4s0" ];
    users.scanner.passwordFile                   = config.age.secrets.samba-scanner.path;
    shares.paperless = {
      path                                       = config.services.paperless.consumptionDir;
      comment                                    = "Paperless consume (scanner drop)";
      "valid users"                              = "scanner";
      "read only"                                = "no";
      "force user"                               = "paperless";
      "force group"                              = "paperless";
      "create mask"                              = "0640";
      "directory mask"                           = "0750";
    };
  };

  # DNS filter for LAN + tailnet, replacing karma's Pi-hole container
  # (phase 1). Clients move over when the router's DHCP and the tailnet's
  # DNS setting point here; until then only by hand.
  myServices.adguard = {
    enable                                       = true;
    listenAddresses                              = [ lanIp tailIp ];
    interfaces                                   = [ "enp4s0" ];
    routerAddress                                = gateway;
  };

  # Push alerts to the phone (ntfy.sh, random topic in agenix) - see
  # modules/services/alerts.nix. Beszel's thresholds use the same topic,
  # set in its UI (Settings > Notifications).
  age.secrets.heartbeat-url.file                 = ../../secrets/heartbeat-url.age;
  age.secrets.healthchecks-ping-key.file         = ../../secrets/healthchecks-ping-key.age;
  myServices.alerts = {
    enable                                       = true;
    heartbeatUrlFile                             = config.age.secrets.heartbeat-url.path; # external down-check (healthchecks.io)
    heartbeatInterval                            = "4min";                     # = the check's period there (grace 8 min)
    healthchecks.pingKeyFile                     = config.age.secrets.healthchecks-ping-key.path;
    healthchecks.checks = {                                                    # unit -> check (set schedules on healthchecks.io)
      sanoid                                     = "kraken-snapshots";         # hourly
      zfs-scrub                                  = "kraken-scrub";             # monthly, pinged when the scrub has finished
      game-saves-backup                          = "kraken-game-saves";        # every 6 h
      paperless-exporter                         = "kraken-paperless-export";  # daily 01:30 (document export = Paperless backup)
    };
    failureUnits = [
      "zfs-zed" "zfs-scrub" "smartd" "scrutiny" "influxdb2" "beszel-hub" "beszel-agent"
      "homepage-dashboard" "wol-web" "tailscaled"
      "airvpn" "qbittorrent" "adguardhome"
      "paperless-scheduler" "paperless-consumer" "paperless-web" "paperless-task-queue" "paperless-exporter"
      "game-saves-backup" "samba-smbd" "samba-users" "filebrowser-quantum" "cloudflare-tunnel" "podman-stemdeck"
    ];
  };

  # qBittorrent behind AirVPN in a WireGuard namespace (phase-4 groundwork,
  # TEST - not the live download client yet; karma's stays in charge).
  # Own AirVPN device "kraken" (config in secrets/airvpn-wg.conf.age).
  # Web UI: http://<lanIp>:8181 (LAN + Tailscale only; karma's port, see karma-services.nix).
  age.secrets.qbittorrent-webui = { file = ../../secrets/qbittorrent-webui.age; };
  systemd.services.qbittorrent.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.qbittorrent-webui.file) ];
  myServices.vpnTorrent = {
    enable                                       = true;
    forwardedPort                                = 11557;                      # AirVPN port assigned to device "kraken"
    seedDays                                     = 7;                          # seed 7 days, then stop; the arrs remove after import
    webuiPasswordFile                            = config.age.secrets.qbittorrent-webui.path; # PBKDF2 hash, survives restarts
  };

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
    rootDevice                                   = "nvme0n1p2";                # the rpool partition (990 Pro). Not "nvme0n1": that matched p1 = /boot. / is ZFS; unset, the agent guessed the T500's old ext4 "root" partition
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
    };
  };

  # Widget credentials (HOMEPAGE_VAR_* lines), loaded by systemd before
  # Homepage drops to its DynamicUser - root 0400 is enough.
  age.secrets.homepage-env.file                  = ../../secrets/homepage-env.age;
  # A changed secret doesn't change the unit (same /run/agenix path), so a
  # rebuild wouldn't restart Homepage - it kept running without the new
  # Paperless token ("Invalid token", 2026-11-24). Tie it to the .age
  # file's content hash (its store path changes with every repo commit).
  systemd.services.homepage-dashboard.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.homepage-env.file) ];

  services.homepage-dashboard = {
    environmentFiles                             = [ config.age.secrets.homepage-env.path ];
    settings = {
      title                                      = hostName;
      headerStyle                                = "clean";
      # GitKraken wallpaper, logo only (lettering removed, re-centred on the
      # flat navy; the squid blended 25% into it, then the whole image at 50%;
      # no Homepage brightness, so the tiles keep their colours).
      # Homepage serves images only from its read-only store folder, so it's
      # embedded as a data URL. After changing the .webp:
      #   base64 -w0 dotfiles/homepage/kraken-bg.webp > dotfiles/homepage/kraken-bg.webp.b64
      background = "data:image/webp;base64,${builtins.readFile ../../dotfiles/homepage/kraken-bg.webp.b64}";
      layout.System = { style = "row"; columns = 4; };
      layout.Network = { style = "row"; columns = 4; };
      layout.Devices = { style = "row"; columns = 2; };
      layout.Downloads = { style = "row"; columns = 2; };
    };
    widgets = [
      # One disk per pool: "/" (rpool - every rpool dataset shares its free
      # space; Homepage's sandbox (ProtectHome) can't see /home anyway),
      # /mnt/games (games SSD), /srv/gamesaves (vault, the 4x 4TB mirrors).
      { resources = { cpu = true; memory = true; disk = [ "/" "/mnt/games" "/srv/gamesaves" ]; cputemp = true; uptime = true; }; }
    ];
    services = [
      {
        System = [
          { Cockpit  = { href = "https://${lanIp}:9090";    icon = "cockpit.png";  description = "System, logs, services, ZFS, files, containers (Podman)"; }; }
          { Scrutiny = { href = "http://${lanIp}:8087";     icon = "scrutiny.png"; description = "Disk health (SMART)"; }; }
          { Beszel   = { href = "http://${lanIp}:8090";     icon = "beszel.png";   description = "Metrics and alerts"; }; }
          { Storage = {
              href = "https://${lanIp}:9090/zfs"; icon = "truenas.png";
              description = "ZFS pools, media array, SnapRAID (myStorage.statusApi)";
              widget = {
                type = "customapi";
                url = "http://127.0.0.1:8189/status.json";
                refreshInterval = 60000;
                display = "list";
                mappings = [
                  { field = "status";     label = "Pools"; }
                  { field = "rpool";      label = "rpool (system)"; }
                  { field = "games";      label = "games (SSD)"; }
                  { field = "vault";      label = "vault (4x 4TB)"; }
                  { field = "scratch";    label = "scratch (downloads)"; }
                  { field = "array";      label = "Media array (disk1-5)"; }
                  { field = "snapraid";   label = "SnapRAID parity"; }
                  { field = "last_scrub"; label = "Oldest scrub"; }
                  { field = "array_scrub"; label = "Media scrub (quarterly)"; }
                ];
              };
          }; }
        ];
      }
      {
        # Moonlight apps (modules/desktop/stream-apps/) have no web UIs of
        # their own - Sunshine's is for pairing and its log.
        Streaming = [
          { Sunshine = {
              href = "https://${streamIp}:47990"; icon = "sunshine.png";
              description = "Moonlight: Steam Big Picture, Zen (VPN), Lutris";
              ping = streamIp;                              # (its web UI answers 401 without login - a site monitor would show "down")
          }; }
        ];
      }
      {
        Media = [
          { StemDeck = {
              href = "https://stemdeck.jpc.onl"; icon = "mdi-waveform";
              description = "Stem separation on the GPU (Cloudflare Access login)";
              siteMonitor = "https://stemdeck.jpc.onl";      # 302 to the login = up (StemDeck refuses plain http)
          }; }
        ];
      }
      {
        Documents = [
          { Files = {
              href = "http://${lanIp}:8095"; icon = "filebrowser-quantum.png";
              description = "FileBrowser Quantum - files, uploads, share links (files.jpc.onl)";
              siteMonitor = "http://127.0.0.1:8095/api/health";
          }; }
          { Paperless = {
              href = "http://${lanIp}:28981"; icon = "paperless-ngx.png";
              description = "Document archive - the scanner drops into it (SMB)";
              siteMonitor = "http://127.0.0.1:28981";
              widget = {
                type = "paperlessngx";
                url = "http://127.0.0.1:28981";
                key = "{{HOMEPAGE_VAR_PAPERLESS_KEY}}";          # API token, from secrets/homepage-env.age
              };
          }; }
        ];
      }
      {
        Network = [
          { AdGuard = {
              href = "http://${lanIp}:3000"; icon = "adguard-home.png";
              description = "DNS filter (LAN + tailnet)";
              widget = { type = "adguard"; url = "http://127.0.0.1:3000"; };
          }; }
          { Router    = { href = "http://${gateway}";                    icon = "router.png";    description = "DIGI ZTE F8748 - DHCP, LAN DNS"; ping = gateway; }; }
          { Tailscale = { href = "https://login.tailscale.com/admin/machines"; icon = "tailscale.png"; description = "Tailnet admin (DNS, routes, keys)"; }; }
          # External down-check + job pings (myServices.alerts). Project id
          # and read-only API key come from homepage-env (agenix).
          { Healthchecks = {
              href = "https://healthchecks.io/projects/{{HOMEPAGE_VAR_HC_PROJECT}}/checks/";
              icon = "healthchecks.png";
              description = "kraken down-check, snapshots, scrub, game saves";
              widget = { type = "healthchecks"; url = "https://healthchecks.io"; key = "{{HOMEPAGE_VAR_HC_KEY}}"; };
          }; }
        ];
      }
      {
        # Printer + scanner web UIs (as on karma's Homepage)
        Devices = [
          { Printer = { href = "http://192.168.1.100"; icon = "brother.svg"; description = "Brother HL-L8230CDW"; siteMonitor = "http://192.168.1.100"; }; }
          { Scanner = { href = "http://192.168.1.101"; icon = "brother.svg"; description = "Brother ADS-4300N";  ping = "192.168.1.101"; }; }   # not siteMonitor: its web server sends a body on HEAD, Homepage's check chokes on it
        ];
      }
      {
        Wake = [
          { kimi           = { href = "http://${lanIp}:8089/wake/kimi";         icon = "nixos.png";  description = "Wake-on-LAN";  ping = "kimi"; }; }
        ];
      }
      {
        # VPN test (myServices.vpnTorrent) - not the live download client yet.
        # Homepage runs on the host, so it reaches qBittorrent at the
        # namespace's own address (192.168.15.1), not through the LAN mapping.
        Downloads = [
          { qBittorrent = {
              href = "http://${lanIp}:8181"; icon = "qbittorrent.png";
              description = "Behind AirVPN (test)";
              siteMonitor = "http://192.168.15.1:8181";
              widget = {
                type = "qbittorrent";
                url = "http://192.168.15.1:8181";
                username = "{{HOMEPAGE_VAR_QBIT_USER}}";        # from secrets/homepage-env.age
                password = "{{HOMEPAGE_VAR_QBIT_PASSWORD}}";
              };
          }; }
          { AirVPN = {
              icon = "wireguard.png";
              description = "WireGuard tunnel of the qBittorrent namespace";
              widget = {
                type = "customapi";
                url = "http://127.0.0.1:8188/status.json";
                refreshInterval = 60000;
                mappings = [
                  { field = "status";     label = "Tunnel"; }
                  { field = "exit_where"; label = "Exit"; }
                  { field = "handshake";  label = "Handshake"; format = "relativeDate"; }
                  { field = "rx";         label = "Received"; format = "bytes"; }
                ];
              };
          }; }
        ];
      }
    ];
  };

  ############################################################
  # Users
  ############################################################
  #
  # zp    - admin: SSH (fleet keys), wheel. Lean home profile
  #         (home/profiles/server.nix). Password from agenix
  #         (secrets/zp-password.age), the same one on every host.
  # steam - Sunshine/Steam/gamescope. Unprivileged: no wheel,
  #         no password.
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
  # 6   Cutover: advertiseRoutes (take over from the Unraid karma), point
  #     what still uses 192.168.1.5 at kraken (modules/shares/nfs nasHost,
  #     app clients), retire the Unraid karma. kraken keeps .10.

  # System state version - the release this host is first installed with.
  system.stateVersion                            = "26.11";
}
