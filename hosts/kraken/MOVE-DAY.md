# karma → kraken: the move

Status: **preparation** (started 2026-11-26). Tick items off as they're done.
Rule throughout: on karma, stop things and keep their data; delete only
after kraken has run the replacement for a while.

## Inventory (2026-11-26)

| karma pool | becomes in kraken | data on it |
|---|---|---|
| disk1–disk5 (5x Exos 16 TB, single-disk ZFS) | media array, imported as-is | media-server 32 T, most of home/backup, trading, photos-array |
| parity (Exos 16 TB) | SnapRAID parity | Unraid parity - untouched until SnapRAID is set up |
| nvme-appdata (T500 500 GB) | scratch | appdata 187 G, backup (part) 71 G, domains 21 G |
| nvme-immich (T500 1 TB) | mirror partner of krieger's T500 | photos 394 G |
| ssd-downloads (SA500 1 TB) | 2nd Steam library / downloads | setup 105 G, system 26 G (docker.img), media cache |
| USB: RTL2838 DVB-T stick | moves along | fr24feed-piaware |
| Unraid USB stick | keep as the way back | |

karma is also the **Tailscale subnet router (192.168.1.0/24) and exit node**,
the **Cloudflare tunnel** for plex/audiobookshelf/seerr.zulupapa.org, and an
**NFS/SMB server** for kuro.

## 1. Copy the data (remote, karma keeps running)

- [ ] datasets: `sudo zfs create -o mountpoint=legacy vault/{home,trading,backup,setup,photos}`
- [ ] rebuild kraken (karma-import.nix: NFS mounts + karma-copy)
- [ ] first copy: `sudo systemctl start karma-copy`, watch `journalctl -fu karma-copy`
      (home, trading, backup, setup, photos → vault; appdata → /srv/appdata/karma; ~2.4 TB)
- [ ] domains (Office VM, not exported): copy separately
- [ ] compare sizes and file counts per share

## 2. Prepare kraken (repo, services off until the disks are in)

- [ ] Tailscale: kraken advertises 192.168.1.0/24 + exit node; approve in the admin
      console; then remove both from karma
- [ ] media array: import disk1–5 read-only first, mergerfs at the old paths
- [ ] Plex (native, GPU), its database from appdata; Tautulli, Kometa, plex-auto-languages
- [ ] arrs + downloaders: Prowlarr, Sonarr, Radarr, Lidarr, Bazarr, SABnzbd,
      qBittorrent (already on kraken), byparr
- [ ] downloads on scratch (T500 500G): qBittorrent incomplete + complete there,
      seeds 7 days then STOPS (seedDays = 7, already in the config); SABnzbd
      temp + unpack there. Sonarr/Radarr/Lidarr download client:
      **"Remove Completed" ON** - they delete a torrent (with files) only
      after importing it, so failed imports stay for a manual import
- [ ] target layout (later, after move day 1:1): one dataset per disk with
      downloads/ and library/ (flat: movies, tvshows, music, ebooks, audiobooks…),
      mergerfs at /mnt/user; arrs + clients mount /mnt/user as /data,
      Plex/ABS keep per-folder mounts
- [ ] Immich (originals on vault, thumbs/DB on the T500 mirror)
- [ ] Audiobookshelf (+ its OIDC login), Seerr, Calibre-Web, LazyLibrarian, ytdl,
      Threadfin/EPG, fr24feed (DVB-T stick), squid home-proxy, Krusader → FileBrowser
- [ ] tunnel routes for plex/audiobookshelf/seerr move to kraken's tunnel per app
      (Plex: prefer Plex's own remote access - Cloudflare's terms forbid video)
- [ ] kuro: NFS mounts point at kraken

## 3. Hardware check (next visit, before move day)

- [ ] BIOS: all 8 onboard SATA ports visible (Linux shows 3 today)
- [ ] ports: 7 more SATA drives (6 Exos + SA500 #2) vs. free ports; if short,
      the 2x WD Red 2 TB (role undecided) come out first
- [ ] N5: bays and SATA power for 6 more 3.5" drives

## 4. Move day

- [ ] final sync: stop karma's containers, `sudo systemctl start --no-block karma-copy`
      (changes only; databases consistent); wait until done
- [ ] karma: shut down cleanly; label the drives with their pool names
- [ ] drives into kraken; boot; check every disk by serial (`lsblk -d -o NAME,SIZE,SERIAL`)
- [ ] read-only check: `sudo zpool import` (lists them), then per disk
      `sudo zpool import -f -o readonly=on diskN`, look at /mnt/diskN, then
      `sudo zpool export diskN` (all five)
- [ ] `sudo karma-fixup` (after the LAST karma-copy): rewrites .5 / gluetun ports in
      Tautulli, Kometa, Seerr, LibreSeerr, Threadfin (prints anything left over)
- [ ] karma-services.nix: `arrayInstalled = true;` commit, rebuild → imports disk1–5
      read-write, mergerfs at /mnt/user, Plex + download group start
- [ ] qBittorrent's torrents (92 on karma): stop qbittorrent, then
      `/srv/appdata/karma/qbittorrent/qBittorrent/BT_backup/*` → `/var/lib/qBittorrent/qBittorrent/data/BT_backup/`,
      `categories.json` → `.../config/`; `chown -R media:users`; start; recheck a few
- [ ] Plex: karma's Plex must be stopped first (same machine ID - never both running);
      name becomes "kraken" by itself (no FriendlyName set); Settings → Transcoder →
      hardware device "Auto" / RTX 4060 Ti (karma pinned the T1000)
- [ ] check: Plex libraries play (GPU transcode), Sonarr/Radarr/Lidarr see their
      root folders + qBittorrent/SABnzbd (Settings → Download Clients → Test),
      Prowlarr → Apps → Test, SABnzbd web UI from the LAN (host_whitelist?)
- [ ] web UIs now on kraken: qBittorrent :8181, SABnzbd :8080, Sonarr :8989,
      Radarr :7878, Lidarr :8686, Prowlarr :9696, Bazarr :6767, LazyLibrarian :5299,
      ytdl :17442, Plex :32400
- [ ] Plex → Settings → Live TV & DVR: tuner (Threadfin) to 192.168.1.10:8050
- [ ] fr24feed: the RTL-SDR stick (+ antenna; ADS-B receiver for the FR24 feed
      T-LPPR184, not TV - IPTV is Threadfin/EPG) moved to kraken, `ls -l /dev/rtl_sdr`;
      status :8754 (feed_status connected, aircraft tracked)
- [ ] Byparr via squid (home IP): Prowlarr → 1337x test search
- [ ] Homepage (karma's) → gone; Plex remote access (router port forward, not the tunnel)
- [ ] after: Immich + Audiobookshelf (separately); Phockup + Calibre (kept, set up later)
- [ ] tunnel routes, kuro's mounts, PS5 to .5 later (LAN plan)

## 5. After

- [ ] SnapRAID with the old parity disk (no parity protection until the first sync)
- [ ] quarterly scrub for the media pool + its healthchecks check
- [ ] delete karma-import.nix; retire karma's Tailscale node and tunnel
- [ ] keep the Unraid stick until kraken has run a few weeks
