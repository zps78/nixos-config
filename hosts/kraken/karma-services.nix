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
  arrayInstalled = false;

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

  containerNames = [ "plex" "plex-auto-languages" ] ++ lib.attrNames vpnPorts;

  displayNames = {
    sabnzbd = "SABnzbd"; sonarr = "Sonarr"; radarr = "Radarr"; lidarr = "Lidarr";
    prowlarr = "Prowlarr"; bazarr = "Bazarr"; lazylibrarian = "LazyLibrarian";
    byparr = "Byparr"; ytdl = "YouTube-DL";
  };
in
{
  # ── storage (move day) ──────────────────────────────────────────────
  age.secrets.plex-auto-languages.file = ../../secrets/plex-auto-languages.age;

  boot.zfs.extraPools = lib.mkIf arrayInstalled disks;   # each mounts at /mnt/diskN (its own mountpoint)
  system.fsPackages = [ pkgs.mergerfs ];
  environment.systemPackages = [ pkgs.mergerfs pkgs.mergerfs-tools ];
  fileSystems."/mnt/user" = lib.mkIf arrayInstalled {
    device = lib.concatMapStringsSep ":" (d: "/mnt/${d}") disks;
    fsType = "fuse.mergerfs";
    options = [
      "allow_other" "use_ino" "cache.files=off" "dropcacheonclose=true"
      "category.create=epmfs"     # new files where their folder exists (keeps hardlinks possible)
      "moveonenospc=true" "minfreespace=100G" "fsname=mergerfs"
      "x-systemd.requires=zfs-mount.service" "x-systemd.after=zfs-mount.service" "nofail"
    ];
  };

  # ── qBittorrent (native, already in the namespace): karma's port + paths
  myServices.vpnTorrent.webuiPort = 8181;                # the arrs expect localhost:8181
  services.qbittorrent = lib.mkIf arrayInstalled {
    user = "media";
    group = "users";
    serverConfig.BitTorrent.Session = {
      DefaultSavePath = "/torrents/complete";
      TempPath = "/torrents/incomplete";
      TempPathEnabled = true;
    };
  };

  # LAN access to the namespace's web UIs
  vpnNamespaces.airvpn.portMappings = lib.mapAttrsToList (_: p: { from = p; to = p; protocol = "tcp"; }) vpnPorts;

  # ── containers ──────────────────────────────────────────────────────
  virtualisation.oci-containers.containers = {
    plex = {
      image = "lscr.io/linuxserver/plex@sha256:31e4c2de666cd130bc389133b6c63af08912559d992370e52822f8f229185aef";
      autoStart = arrayInstalled;
      environment = lsio // { VERSION = "docker"; };
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

    sabnzbd = inVpn {
      image = "lscr.io/linuxserver/sabnzbd@sha256:d225bbab93f54784c115a3b1d89711e469b1969c9f32aa6ebb11fb03b5804431";
      environment = lsio;
      volumes = [ "${appdata}/sabnzbd:/config" "${media}/usenet:/data/usenet" ];
    };
    prowlarr = inVpn {
      image = "lscr.io/linuxserver/prowlarr@sha256:2806c9b763810589c42157730d547c293639e55c7610e9f5069314854639ec48";
      environment = lsio;
      volumes = [ "${appdata}/prowlarr:/config" ];
    };
    byparr = inVpn {
      image = "ghcr.io/thephaseless/byparr@sha256:c66fa161187b8fa527bfad7eefa2647ea1c553f77df68cbffd6fe83366d1787b";
      # karma used PROXY_SERVER=http://192.168.1.5:3128 (squid home-proxy
      # for 1337x) - set again once the proxy has moved to kraken
      environment = { PORT = "8191"; HOST = "0.0.0.0"; BROWSER_LOCALE = "en-US"; TZ = config.time.timeZone; };
    };
    sonarr = inVpn {
      image = "lscr.io/linuxserver/sonarr@sha256:339814bbf50599ac3b59077c252f29833d0138b59a062d0e82ce37bdc7f04f86";
      environment = lsio;
      volumes = [ "${appdata}/sonarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/tvshows:/tvshows" "${media}/usenet:/data/usenet" ];
    };
    radarr = inVpn {
      image = "lscr.io/linuxserver/radarr@sha256:044788f5508b7f67a3e0368cdd142c77c4d4cd5aec2efaba53e1a68b6b6231e7";
      environment = lsio;
      volumes = [ "${appdata}/radarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/movies:/movies" "${media}/usenet:/data/usenet" ];
    };
    lidarr = inVpn {
      image = "lscr.io/linuxserver/lidarr@sha256:c4285344c994b34e1ae7db8d57c1702dcfe88b8e10c98a0cdf0f74aba8b58b9c";
      environment = lsio;
      volumes = [ "${appdata}/lidarr:/config" "${media}/torrents/complete:/downloads"
                  "${media}/media/music:/music" "${media}/usenet:/data/usenet" ];
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
                  "${media}/usenet:/data/usenet" ];
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
      unitConfig.RequiresMountsFor = [ appdata ] ++ lib.optional arrayInstalled media;
    }))
    # new token -> restart
    { podman-plex-auto-languages.restartTriggers = [ (builtins.hashFile "sha256" config.age.secrets.plex-auto-languages.file) ];
      podman-plex-auto-languages.after = [ "podman-plex.service" ]; }
    # the VPN ones: only with the namespace up
    (lib.genAttrs (map (n: "podman-${n}") (lib.attrNames vpnPorts)) (_: {
      after = [ "airvpn.service" ];
      requires = [ "airvpn.service" ];
    }))
    # qBittorrent: karma's container paths, as media:users
    (lib.mkIf arrayInstalled {
      qbittorrent = {
        unitConfig.RequiresMountsFor = [ media ];
        serviceConfig.BindPaths = [
          "${media}/torrents:/torrents"                  # the arrs' path mapping (localhost:/torrents/complete/) stays valid
          "${media}/media/books-ingest:/ebook-ingest"
        ];
        serviceConfig.UMask = lib.mkForce "0022";
      };
    })
  ];
}
