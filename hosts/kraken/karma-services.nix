# ../../hosts/kraken/karma-services.nix
#
# MOVE DAY, 1:1: karma's Plex and download group as Podman containers with
# the same images (pinned to the digests karma ran), the same container
# paths and the same uid/gid (99:100 = media:users), so no app setting
# changes: the arrs keep talking to each other and to qBittorrent/SABnzbd
# via localhost (they share kraken's VPN namespace "airvpn", like karma's
# gluetun container), Plex keeps its library paths (/movies, /tvshows...).
#
# Switch: arrayInstalled. false (until the disks are in): containers are
# defined but never start, nothing references the array. true (move day,
# after a read-only import + check): imports disk1-5, mergerfs at
# /mnt/user, qBittorrent sees /torrents, containers start at boot.
#
# Appdata comes from karma-copy (/srv/appdata/karma/<app>); run the final
# sync with karma's containers stopped first. Converting to native
# services / the downloads+library layout comes later (MOVE-DAY.md).
{ config, lib, pkgs, ... }:

let
  arrayInstalled = true;   # 2026-11-27: disks in kraken, read-only import checked clean

  appdata = "/srv/appdata/karma";
  media = "/mnt/user/media-server";
  disks = [ "disk1" "disk2" "disk3" "disk4" "disk5" ];

  # linuxserver.io settings as on karma
  lsio = { PUID = "99"; PGID = "100"; UMASK = "022"; TZ = config.time.timeZone; };

  # web UI port of each container in the VPN namespace (host port = app
  # port, mapped into the namespace by VPN-Confinement)
  vpnPorts = {
    sabnzbd = 8080; sonarr = 8989; radarr = 7878; lidarr = 8686; prowlarr = 9696;
    bazarr = 6767; lazylibrarian = 5299; byparr = 8191; ytdl = 17442;
  };

  # a container inside the VPN namespace: reaches the others (and the
  # native qBittorrent) on localhost, DNS through the tunnel
  inVpn = c: c // {
    autoStart = arrayInstalled;
    extraOptions = [ "--network=ns:/run/netns/airvpn" "--dns=10.128.0.1" ];
  };

  # the rest of karma's apps, on Podman's default network, published on
  # the same host ports as on karma (so their mutual references only change
  # .5 -> .10, see karmaFixup)
  bridgeApps = [ "tautulli" "kometa" "seerr" "calibre-web-automated" "libreseerr"
                 "threadfin" "epg" "fr24feed" "home-proxy" ];

  containerNames = [ "plex" "plex-auto-languages" ] ++ lib.attrNames vpnPorts ++ bridgeApps;

  # karma's squid (home-IP proxy for Byparr/1337x), with the VPN namespace
  # (Byparr's new origin) instead of Docker's bridge as the allowed source
  squidConf = pkgs.writeText "squid.conf" ''
    http_port 192.168.15.5:3128
    acl vpn_ns        src 192.168.15.0/24
    acl safe_ports    port 80 443
    acl ssl_ports     port 443
    acl connect_m     method CONNECT
    acl private_dst   dst 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16 100.64.0.0/10 127.0.0.0/8 0.0.0.0/8 fc00::/7 fe80::/10 ::1
    http_access deny !safe_ports
    http_access deny connect_m !ssl_ports
    http_access deny private_dst
    http_access allow vpn_ns
    http_access deny all
    cache deny all
    dns_nameservers 94.140.14.14 94.140.15.15
    via off
    forwarded_for delete
    access_log none
    cache_log stdio:/dev/stderr
    coredump_dir /var/spool/squid
  '';

  # Move day, AFTER the final karma-copy and BEFORE flipping arrayInstalled:
  # rewrite karma's address (and its gluetun ports) in the copied configs.
  # Idempotent; a later karma-copy run would undo it (run this again then).
  karmaFixup = pkgs.writeShellScriptBin "karma-fixup" ''
    set -eu
    A=${appdata}
    # rewrite in place, keeping owner and mode
    edit() { f=$1; shift; t=$(mktemp); "$@" < "$f" > "$t" && cat "$t" > "$f"; rm -f "$t"; }
    edit $A/tautulli/config.ini sed -E 's|^pms_ip = .*|pms_ip = 192.168.1.10|; s|^pms_url = .*|pms_url = http://192.168.1.10:32400|'
    edit $A/kometa/config.yml sed -E 's|http://192\.168\.1\.5:1060|http://192.168.1.10:8989|g; s|http://192\.168\.1\.5:1070|http://192.168.1.10:7878|g; s#http://192\.168\.1\.5:(32400|8030)#http://192.168.1.10:\1#g'
    edit $A/seerr/settings.json ${pkgs.jq}/bin/jq '.plex.ip = "192.168.1.10"
      | .sonarr |= map(.hostname = "192.168.1.10" | if .port == 1060 then .port = 8989 else . end)
      | .radarr |= map(.hostname = "192.168.1.10" | if .port == 1070 then .port = 7878 else . end)'
    edit $A/libreseerr/config.json ${pkgs.jq}/bin/jq '(.ebook.url, .audiobook.url) |= sub("192\\.168\\.1\\.5:1090"; "192.168.1.10:5299")'
    for f in $A/threadfin/config/settings.json $A/threadfin/config/data/threadfin.xml $A/threadfin/config/data/threadfin.m3u; do
      [ -f "$f" ] && edit "$f" sed 's|192\.168\.1\.5:80\([56]0\)|192.168.1.10:80\1|g'
    done
    # Plex's "custom server access URL" (the tunnel fallback): zulupapa.org -> jpc.onl
    P="$A/plex/Library/Application Support/Plex Media Server/Preferences.xml"
    edit "$P" sed 's|customConnections="https://plex\.zulupapa\.org:443"|customConnections="https://plex.jpc.onl:443"|'
    grep -o 'customConnections="[^"]*"' "$P"
    echo "left over (should be empty except history/backups):"
    grep -rIl --exclude-dir={cache,logs,log,Logs,backups,temp,db} -e '192\.168\.1\.5[:" ]' \
      $A/tautulli $A/kometa $A/seerr $A/libreseerr $A/threadfin 2>/dev/null || true
  '';

  displayNames = {
    sabnzbd = "SABnzbd"; sonarr = "Sonarr"; radarr = "Radarr"; lidarr = "Lidarr";
    prowlarr = "Prowlarr"; bazarr = "Bazarr"; lazylibrarian = "LazyLibrarian";
    byparr = "Byparr"; ytdl = "YouTube-DL";
  };

  # qBittorrent AutoRun (karma's /config/scripts/route-epub.sh): $1 =
  # category, $2 = content path, as qBittorrent sees them
  routeEpub = pkgs.writeShellScript "route-epub" ''
    PATH=${lib.makeBinPath [ pkgs.findutils pkgs.coreutils ]}
    [ "$1" = lazylibrarian ] || exit 0
    has_audio=$(find "$2" -type f \( -iname '*.mp3' -o -iname '*.m4b' -o -iname '*.m4a' \) 2>/dev/null | head -1)
    has_ebook=$(find "$2" -type f \( -iname '*.epub' -o -iname '*.mobi' \) 2>/dev/null | head -1)
    if [ -n "$has_audio" ] && [ -n "$has_ebook" ]; then
      find "$2" -type f \( -iname '*.epub' -o -iname '*.mobi' \) -exec cp -n {} /ebook-ingest/ \;
    fi
  '';
in
{
  # ── storage (move day) ──────────────────────────────────────────────
  age.secrets.plex-auto-languages.file = ../../secrets/plex-auto-languages.age;
  age.secrets.fr24feed.file = ../../secrets/fr24feed.age;   # FR24FEED_FR24KEY=<key>

  # the RTL-SDR stick (ADS-B receiver for the FR24 feed - sold as a DVB-T
  # stick, not used for TV): kernel DVB drivers off, /dev/rtl_sdr as on karma
  hardware.rtl-sdr.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", SYMLINK+="rtl_sdr", MODE="0660", GROUP="plugdev"
  '';

  # Seerr, Kometa, LibreSeerr (Podman's default network 10.88.0.0/16)
  # reach the arrs inside the VPN namespace through its port mappings
  myServices.vpnTorrent.allowedIngress = [ "192.168.1.0/24" "100.64.0.0/10" "10.88.0.0/16" ];

  boot.zfs.extraPools = lib.mkIf arrayInstalled disks;   # each mounts at /mnt/diskN (its own mountpoint)
  system.fsPackages = [ pkgs.mergerfs ];
  environment.systemPackages = [ pkgs.mergerfs pkgs.mergerfs-tools karmaFixup ];   # move day: sudo karma-fixup
  fileSystems."/mnt/user" = lib.mkIf arrayInstalled {
    device = lib.concatMapStringsSep ":" (d: "/mnt/${d}") disks;
    fsType = "fuse.mergerfs";
    options = [
      "allow_other" "use_ino" "cache.files=off" "dropcacheonclose=true"
      "category.create=epmfs"     # new files where their folder exists (keeps hardlinks possible)
      "moveonenospc=true" "minfreespace=100G" "fsname=mergerfs"
      "noforget" "inodecalc=path-hash"   # stable inodes for NFS clients (no "stale file handle")
      "x-systemd.requires=zfs-mount.service" "x-systemd.after=zfs-mount.service" "nofail"
    ];
  };

  # ── NFS for kuro, krugerrand, kimi, kepler (modules/shares/nfs, its
  # `server` flips to "kraken" on move day). Same options as karma's
  # Unraid exports; Paperless's originals read-only, read as its user.
  # fsid on the mergerfs paths (a FUSE filesystem has no stable one).
  services.nfs.server = lib.mkIf arrayInstalled {
    enable = true;
    exports = let
      nets = [ "192.168.1.0/24" "100.64.0.0/10" ];
      rw = id: lib.concatMapStringsSep " " (n: "${n}(rw,async,no_subtree_check,no_root_squash,insecure${lib.optionalString (id != null) ",fsid=${toString id}"})") nets;
      ro-as = uid: lib.concatMapStringsSep " " (n: "${n}(ro,async,no_subtree_check,all_squash,anonuid=${toString uid},anongid=${toString uid},insecure)") nets;
    in ''
      /srv/backup                                  ${rw null}
      /srv/home                                    ${rw null}
      /srv/trading                                 ${rw null}
      ${media}/media                    ${rw 101}
      ${media}/torrents/complete        ${rw 102}
      /var/lib/paperless/media/documents/originals ${ro-as config.users.users.paperless.uid}
    '';
  };
  networking.firewall.interfaces.enp4s0 = lib.mkIf arrayInstalled {
    allowedTCPPorts = [ 2049 32400 ];          # NFSv4; Plex (host network - on karma Docker opened it)
    allowedUDPPorts = [ 32410 32412 32413 32414 ];   # Plex GDM: LAN clients find the server by themselves
  };                                           # (tailscale0 is trusted anyway)

  # ── qBittorrent (native, already in the namespace): karma's port + paths
  myServices.vpnTorrent.webuiPort = 8181;                # the arrs expect localhost:8181
  # The NixOS module rewrites qBittorrent.conf from serverConfig at every
  # start, so settings changed in the web UI don't survive a restart - they
  # live here. Taken from karma's qBittorrent.conf (2026-11-27), seeding per
  # myServices.vpnTorrent.seedDays (7 days, then stop; the arrs delete).
  services.qbittorrent = lib.mkIf arrayInstalled {
    user = "media";
    group = "users";
    serverConfig = {
      BitTorrent = {
        MergeTrackersEnabled = true;               # same torrent added twice -> trackers merged
        Session = {
          # downloads on the scratch SSD (hosts/kraken/array.nix)
          DefaultSavePath = "/scratch/torrents/complete";
          TempPath = "/scratch/torrents/incomplete";
          TempPathEnabled = true;
          # automatic torrent management, as on karma: a category ("radarr",
          # "sonarr", ...) saves to <DefaultSavePath>/<category>
          DisableAutoTMMByDefault = lib.mkForce false;
          # queue and connections (karma's values)
          QueueingSystemEnabled = true;
          MaxActiveDownloads = 10;
          MaxActiveUploads = 4;
          MaxActiveTorrents = 40;
          IgnoreSlowTorrentsForQueueing = true;    # stalled torrents don't block the queue
          SlowTorrentsDownloadRate = 20;           # KiB/s
          SlowTorrentsUploadRate = 20;
          MaxConnections = 400;
          MaxConnectionsPerTorrent = 100;
          MaxUploads = 10;
          # never download files that are malware in fake releases
          ExcludedFileNamesEnabled = true;
          ExcludedFileNames = "*.exe, *.lnk, *.scr, *.bat, *.cmd, *.com, *.pif, *.vbs, *.msi, *.zipx";
        };
      };
      Application.MemoryWorkingSetLimit = 1024;    # MiB (default 512)
      Network.PortForwardingEnabled = false;       # no UPnP/NAT-PMP: the port is forwarded at AirVPN
      Preferences = {
        General.Locale = "en";
        Connection.ResolvePeerCountries = true;
        # No login for the arrs: they all reach qBittorrent as localhost
        # inside the namespace. Without this, one app with a wrong/empty
        # password (Lidarr) got localhost banned for everyone (403 in
        # Sonarr, 2026-11-27). Also LAN + tailnet without login, like karma.
        WebUI = {
          LocalHostAuth = false;
          AuthSubnetWhitelistEnabled = true;
          AuthSubnetWhitelist = "192.168.1.0/24, 100.64.0.0/10";
        };
      };
      # karma's AutoRun: LazyLibrarian downloads with an audiobook AND an
      # e-book -> copy the e-books to Calibre-Web-Automated's ingest folder
      # (/ebook-ingest, a BindPath below). Quotes escaped like karma's conf.
      AutoRun = {
        enabled = true;
        program = ''${routeEpub} \"%L\" \"%F\"'';
      };
    };
  };

  # squid (home-proxy, host network, 192.168.15.5:3128) for Byparr: the
  # namespace's kill switch drops every new connection over the bridge
  # that isn't in allowedEgress - so exactly squid's address, nothing
  # else on the host or LAN (2026-11-27). The port is open on the bridge only.
  vpnNamespaces.airvpn.allowedEgress = [ "192.168.15.5" ];
  networking.firewall.interfaces.airvpn-br.allowedTCPPorts = [ 3128 ];

  # LAN access to the namespace's web UIs
  vpnNamespaces.airvpn.portMappings = lib.mapAttrsToList (_: p: { from = p; to = p; protocol = "tcp"; }) vpnPorts;

  # ── containers ──────────────────────────────────────────────────────
  virtualisation.oci-containers.containers = {
    plex = {
      image = "lscr.io/linuxserver/plex@sha256:31e4c2de666cd130bc389133b6c63af08912559d992370e52822f8f229185aef";
      autoStart = arrayInstalled;
      environment = lsio // {
        VERSION = "docker";
        # CDI mounts the NVIDIA libraries under their Nix path and registers
        # them in the container's ld cache - Plex's transcoder has its own
        # loader that ignores that cache ("Cannot load libcuda.so.1", CPU
        # transcoding, 2026-11-27). Point it at the driver's lib dir.
        LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";
      };
      volumes = [
        "${appdata}/plex:/config"
        "${media}/media/movies:/movies"
        "${media}/media/tvshows:/tvshows"
        "${media}/media/music:/music"
        "${media}/media/chess:/chess"
        "${media}/media/trading:/trading"
        "${media}/media/volleyball:/volleyball"
      ];
      extraOptions = [ "--network=host" "--device=nvidia.com/gpu=all" "--tmpfs=/transcode:size=16g" ];
    };

    # sets each show's audio/subtitle language from what you watch; no
    # config file - all env, the Plex token from agenix
    # (PLEX_TOKEN=<token>, secrets/plex-auto-languages.age)
    plex-auto-languages = {
      image = "docker.io/journeyover/plex-auto-languages@sha256:51224217f7a036e93ba0153d1c03d54b174d0fd9099f3e8873ee702b28bac23f";
      autoStart = arrayInstalled;
      environment = {
        PLEX_URL = "http://127.0.0.1:32400";             # host network, same box as Plex
        TRIGGER_ON_PLAY = "true"; TRIGGER_ON_SCAN = "true"; TRIGGER_ON_ACTIVITY = "false";
        REFRESH_LIBRARY_ON_SCAN = "true";
        SCHEDULER_ENABLE = "true"; SCHEDULER_SCHEDULE_TIME = "02:00";
        IGNORE_LABELS = "PAL_IGNORE"; DEBUG = "false"; TZ = config.time.timeZone;
      };
      environmentFiles = [ config.age.secrets.plex-auto-languages.path ];
      volumes = [ "${appdata}/plex-auto-languages:/config" ];
      extraOptions = [ "--network=host" ];
    };

    # ── the rest, on Podman's default network (same host ports as karma) ──
    tautulli = {
      image = "lscr.io/linuxserver/tautulli@sha256:5e8f80cc18f03c606a3567c8a9b37d80812ed8017d2e2f8ff2e2a91b54a3aef1";
      autoStart = arrayInstalled;
      environment = lsio;
      volumes = [ "${appdata}/tautulli:/config" ];
      ports = [ "8030:8181" ];
    };
    kometa = {
      image = "docker.io/kometateam/kometa@sha256:4e45d12ca8cb21b5a47a25917542dbb305fc0c76a366bc692ae9490da35d168d";
      autoStart = arrayInstalled;
      environment = { KOMETA_TIME = "03:00"; LOW_PRIORITY = "True"; TZ = config.time.timeZone; };
      # (its Plex token is in its own config.yml, copied with the appdata)
      volumes = [ "${appdata}/kometa:/config" ];
    };
    seerr = {
      image = "ghcr.io/seerr-team/seerr@sha256:aadee014b40e28cf9aa4928bc9d1183a6eb08f8c44d543cddc9efdcb16549be2";
      autoStart = arrayInstalled;
      environment = { TZ = config.time.timeZone; };
      volumes = [ "${appdata}/seerr:/app/config" ];
      ports = [ "5055:5055" ];                                          # tunnel route seerr.* -> localhost:5055 later
    };
    calibre-web-automated = {
      image = "docker.io/crocodilestick/calibre-web-automated@sha256:5e00373854247750cc3e4479b492ae09293ff5e06ed10177f226634d97888679";
      autoStart = arrayInstalled;
      environment = lsio;
      volumes = [ "${appdata}/calibre-web-automated:/config" "${media}/media/books:/calibre-library"
                  "${media}/media/books-ingest:/cwa-book-ingest" ];
      ports = [ "12020:8083" ];
    };
    libreseerr = {
      image = "ghcr.io/zamnzim/libreseerr@sha256:820134e44279c964ddf54090ab45b444a28e7f562256baaadf20fffaf36911f3";
      autoStart = arrayInstalled;
      environment = lsio;
      volumes = [ "${appdata}/libreseerr:/app/data" ];
      ports = [ "12030:5000" ];
    };
    threadfin = {
      image = "docker.io/fyb3roptik/threadfin@sha256:5b370c9b7f5fc89d32ea0a4286e3fb07de630f63a7b11f2c5a7be07dc7b900a5";
      autoStart = arrayInstalled;
      environment = { PUID = "1001"; TZ = "Europe/London"; };          # as on karma
      volumes = [ "${appdata}/threadfin/config:/home/threadfin/conf" "${appdata}/threadfin/temp:/tmp/threadfin" ];
      ports = [ "8050:34400" ];
      extraOptions = [ "--device=nvidia.com/gpu=all" ];
    };
    epg = {
      image = "ghcr.io/iptv-org/epg@sha256:f03b79e0e6e27d94e5234bd38a33fe4fc53234b12c73ad8bfd304a6f1eef8492";
      autoStart = arrayInstalled;
      environment = { RUN_AT_STARTUP = "true"; TZ = config.time.timeZone; };
      volumes = [ "${appdata}/epg:/epg/public" ];
      ports = [ "8060:3000" ];
    };
    fr24feed = {
      image = "docker.io/thomx/fr24feed-piaware@sha256:49c1f06aa1a6b7c49b400810259b894e63ca34d79717aaa4d8aa31269aa4d022";
      autoStart = arrayInstalled;
      environment = {
        SERVICE_ENABLE_FR24FEED = "true"; SERVICE_ENABLE_DUMP1090 = "true"; SERVICE_ENABLE_HTTP = "true";
        SERVICE_ENABLE_PIAWARE = "false"; SERVICE_ENABLE_ADSBEXCHANGE = "false"; SERVICE_ENABLE_OPENSKY = "false";
        SERVICE_ENABLE_ADSBHUB = "false"; SERVICE_ENABLE_ADSBFI = "false"; SERVICE_ENABLE_PLANEFINDER = "false";
        FR24FEED_RECEIVER = "avr-tcp"; FR24FEED_HOST = "127.0.0.1:30002"; FR24FEED_BS = "no"; FR24FEED_RAW = "no";
        FR24FEED_MLAT = "no"; FR24FEED_MLAT_DASH_WITHOUT_DASH_GPS = "no"; FR24FEED_LOGMODE = "1";
        TZ = config.time.timeZone;
      };
      environmentFiles = [ config.age.secrets.fr24feed.path ];         # FR24FEED_FR24KEY
      volumes = [
        "${appdata}/fr24feed-piaware/fr24feed.ini:/etc/fr24feed.ini"
        "${appdata}/fr24feed-piaware/piaware.conf:/etc/piaware.conf"
      ];
      ports = [ "11010:8080" "8754:8754" ];
      extraOptions = [ "--device=/dev/rtl_sdr" ];                       # the RTL-SDR stick (udev symlink above)
    };
    home-proxy = {
      image = "docker.io/ubuntu/squid@sha256:6a097f68bae708cedbabd6188d68c7e2e7a38cedd05a176e1cc0ba29e3bbe029";
      autoStart = arrayInstalled;
      environment = { TZ = config.time.timeZone; };
      volumes = [ "${squidConf}:/etc/squid/squid.conf:ro" ];
      # host network, listening only on the VPN bridge's host side - not
      # reachable from the LAN. The namespace may connect to it thanks to
      # allowedEgress (namespace settings above; its kill switch drops every other new
      # connection that doesn't go through the tunnel).
      extraOptions = [ "--network=host" "--tmpfs=/var/log/squid" "--tmpfs=/var/spool/squid" ];
    };

    sabnzbd = inVpn {
      image = "lscr.io/linuxserver/sabnzbd@sha256:d225bbab93f54784c115a3b1d89711e469b1969c9f32aa6ebb11fb03b5804431";
      environment = lsio;
      volumes = [ "${appdata}/sabnzbd:/config" "/mnt/scratch/usenet:/data/usenet" ];   # usenet on the scratch SSD
    };
    prowlarr = inVpn {
      image = "lscr.io/linuxserver/prowlarr@sha256:2806c9b763810589c42157730d547c293639e55c7610e9f5069314854639ec48";
      environment = lsio;
      volumes = [ "${appdata}/prowlarr:/config" ];
    };
    byparr = inVpn {
      image = "ghcr.io/thephaseless/byparr@sha256:c66fa161187b8fa527bfad7eefa2647ea1c553f77df68cbffd6fe83366d1787b";
      # squid home-proxy (1337x via the home IP), now home-proxy below,
      # reached on the VPN bridge's host side
      environment = { PORT = "8191"; HOST = "0.0.0.0"; BROWSER_LOCALE = "en-US"; TZ = config.time.timeZone;
                      PROXY_SERVER = "http://192.168.15.5:3128"; };
    };
    sonarr = inVpn {
      image = "lscr.io/linuxserver/sonarr@sha256:339814bbf50599ac3b59077c252f29833d0138b59a062d0e82ce37bdc7f04f86";
      environment = lsio;
      volumes = [ "${appdata}/sonarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/tvshows:/tvshows" "/mnt/scratch/usenet:/data/usenet" "/mnt/scratch:/scratch" ];
    };
    radarr = inVpn {
      image = "lscr.io/linuxserver/radarr@sha256:044788f5508b7f67a3e0368cdd142c77c4d4cd5aec2efaba53e1a68b6b6231e7";
      environment = lsio;
      volumes = [ "${appdata}/radarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/movies:/movies" "/mnt/scratch/usenet:/data/usenet" "/mnt/scratch:/scratch" ];
    };
    lidarr = inVpn {
      image = "lscr.io/linuxserver/lidarr@sha256:c4285344c994b34e1ae7db8d57c1702dcfe88b8e10c98a0cdf0f74aba8b58b9c";
      environment = lsio;
      volumes = [ "${appdata}/lidarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/music:/music" "/mnt/scratch/usenet:/data/usenet" "/mnt/scratch:/scratch" ];
    };
    bazarr = inVpn {
      image = "lscr.io/linuxserver/bazarr@sha256:b3db4247d3afa0c68bc5aa311bedd67b1caf4b3eabc3a85577682970435d5013";
      environment = lsio;
      volumes = [ "${appdata}/bazarr:/config" "${media}/media:/data/media" ];
    };
    lazylibrarian = inVpn {
      image = "lscr.io/linuxserver/lazylibrarian@sha256:aae834d6f933cd6339b19f23c42f7d154b8eff8bd5b31f6705e5e605f0bd0170";
      environment = lsio;
      volumes = [ "${appdata}/lazylibrarian:/config" "${media}/media/audiobooks:/audiobooks"
                  "${media}/torrents/complete:/downloads" "${media}/media/books-ingest:/ebook-ingest"
                  "/mnt/scratch/usenet:/data/usenet" "/mnt/scratch:/scratch" ];
    };
    ytdl = inVpn {
      image = "docker.io/voc0der/ytdl-material@sha256:539537413dce9279a5b9ee030320eb22792a2f20673d1f566a6521b9becf124b";
      environment = { ytdl_use_local_db = "true"; write_ytdl_config = "true"; UID = "1000"; GID = "1000"; TZ = config.time.timeZone; };
      volumes = [ "${appdata}/youtubedl-material:/app/appdata" "${media}/youtube-dl/audio:/app/audio"
                  "${media}/youtube-dl/subscriptions:/app/subscriptions" "${media}/youtube-dl/video:/app/video" ];
    };
  };

  # Homepage tiles - only with the array in, so nothing shows red before
  # move day. (The VPN UIs are monitored on the namespace address; kraken
  # can't reach its own port mappings via its LAN IP.)
  services.homepage-dashboard = lib.mkIf arrayInstalled {
    services = lib.mkAfter [
      { Library = [
          { Plex = {
              href = "http://192.168.1.10:32400/web"; icon = "plex.png";
              description = "Movies, TV, music (GPU transcoding)";
              siteMonitor = "http://127.0.0.1:32400/identity";
          }; }
        ];
      }
      { Arrs = lib.mapAttrsToList (name: port: {
          ${displayNames.${name}} = {
            href = "http://192.168.1.10:${toString port}";
            icon = if name == "ytdl" then "ytdl-material.png" else "${name}.png";
            siteMonitor = "http://192.168.15.1:${toString port}";
          };
        }) (removeAttrs vpnPorts [ "byparr" ]);
      }
    ];
    settings.layout.Arrs = { style = "row"; columns = 4; };
  };

  systemd.services = lib.mkMerge [
    # every container: never start on a missing appdata / array mount
    (lib.genAttrs (map (n: "podman-${n}") containerNames) (_: {
      unitConfig.RequiresMountsFor = [ appdata ] ++ lib.optionals arrayInstalled [ media "/mnt/scratch" ];
    }))
    # new token -> restart
    { podman-plex-auto-languages.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.plex-auto-languages.file) ];
      podman-fr24feed.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.fr24feed.file) ];
      podman-plex-auto-languages.after = [ "podman-plex.service" ]; }
    # the VPN ones: only with the namespace up
    (lib.genAttrs (map (n: "podman-${n}") (lib.attrNames vpnPorts)) (_: {
      after = [ "airvpn.service" ];
      requires = [ "airvpn.service" ];
    }))
    # qBittorrent: karma's container paths, as media:users
    (lib.mkIf arrayInstalled {
      nfs-server.unitConfig.RequiresMountsFor = [ "/mnt/user" "/srv/home" "/srv/backup" "/srv/trading" ];
      qbittorrent = {
        unitConfig.RequiresMountsFor = [ media "/mnt/scratch" ];
        serviceConfig.BindPaths = [
          "${media}/torrents:/torrents"                  # the arrs' path mapping (localhost:/torrents/complete/) stays valid
          "/mnt/scratch:/scratch"                        # new downloads (same path in the arrs - no mapping needed)
          "${media}/media/books-ingest:/ebook-ingest"
        ];
        serviceConfig.UMask = lib.mkForce "0022";
      };
    })
  ];
}
