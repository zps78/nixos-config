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
| nvme-immich (T500 1 TB) | mirror partner of krieger's T500 (wiped 2026-11-26, partition "spare-t500") | photos 394 G |
| ssd-downloads (SA500 1 TB) | 2nd Steam library / downloads | setup 105 G, system 26 G (docker.img), media cache |
| USB: RTL2838 DVB-T stick | moves along | fr24feed-piaware |
| Unraid USB stick | keep as the way back | |

karma is also the **Tailscale subnet router (192.168.1.0/24) and exit node**,
the **Cloudflare tunnel** for plex/audiobookshelf/seerr.zulupapa.org, and an
**NFS/SMB server** for kuro.

Drives by serial (label them when they come out):

| karma pool | drive | serial | in kraken |
|---|---|---|---|
| disk1 | Exos 16TB | ZL2N1V8Y | data |
| disk2 | Exos 16TB | ZL2JBYRR | data |
| disk3 | Exos 16TB | ZL2MVWY6 | data (+ photos-array) |
| disk4 | Exos 16TB | ZL256V1X | data |
| disk5 | Exos 16TB | ZL2D1N7G | data (emptiest) |
| parity | Exos 16TB | ZL2MZHEP | SnapRAID parity later - can wait |
| nvme-appdata | T500 500GB | 233643AA4C32 | scratch (M.2_2) |
| nvme-immich | T500 1TB | 2335458EF62C | PA52L, Immich mirror |
| ssd-downloads | SA500 1TB | 23151H447302 | 2nd Steam library / scratch - can wait |

Plus the RTL-SDR stick + antenna; the Unraid USB stick stays as the way back.
Already in kraken and empty (wiped 2026-11-26, named partitions, nothing on them):
WD Red 2TB WD-WMC300115937 "spare-2tb-a", WD-WMC300112859 "spare-2tb-b" (role
undecided; can come out if SATA ports run short), krieger's T500 1TB 2409474EC4D9
"spare-t500" (Immich mirror; zpool create replaces the label).

## 1. Copy the data (remote, karma keeps running)

- [ ] datasets: `sudo zfs create -o mountpoint=legacy vault/{home,trading,backup,setup,photos}`
- [x] rebuild kraken (karma-import.nix: NFS mounts + karma-copy)
- [ ] first copy: `sudo systemctl start karma-copy`, watch `journalctl -fu karma-copy`
      (home, trading, backup, setup, photos → vault; appdata → /srv/appdata/karma; ~2.4 TB)
- [x] domains (Office VM, not exported): copied separately 2026-11-26 to kraken ~/office-vm
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
- [x] NFS clients: modules/shares/nfs `server = "kraken";` (2026-11-27; karma entry removed) (after kraken runs with
      arrayInstalled = true and its NFS server is up), commit, rebuild kuro, krugerrand,
      kimi, kepler; /mnt/paperless becomes Paperless's originals, read-only

## 3. Hardware check (next visit, before move day)

- [ ] **SATA first**: Linux sees only 2 onboard ports ("ahci 0000:09:00.0 / 0a:00.0:
      1/1 ports implemented"; one is the SA500). The BIOS has no port enable switches,
      only hot-plug per port. Test: hot-plug ENABLED on all onboard ports, boot,
      `journalctl -k -b | grep "ports implemented"` - or plug the (empty) 2TB spares
      into onboard ports and check `lsblk`. If still 2: ASM1166 full (6), so drop the
      2TB spares, USB dock for the rest temporarily, or a second SATA card first
      (an M.2 one takes the scratch slot - SA500 #2 becomes scratch then)
- [ ] ports: 7 more SATA drives (6 Exos + SA500 #2) vs. free ports; if short,
      the 2x WD Red 2 TB (role undecided) come out first
- [ ] N5: bays and SATA power for 6 more 3.5" drives

## 4. Move day

- [x] karma: stop ALL containers (Docker → Stop All) - 2026-11-26 23:3x
- [x] karma: run the mover by hand (done, cache empty) (Main → Move / `mover start`) until
      /mnt/ssd-downloads/media-server is empty - 14 GB of recent media live only on that
      cache SSD (2026-11-26), and media-server is NOT in karma-copy (it comes on the disks)
- [x] final sync: `sudo systemctl start --no-block karma-copy` (23:45-00:18; rsync dry run: 0 differences in all six shares)
      (changes only; databases consistent); wait until done
- [x] karma: shut down cleanly (powerdown 02:58, off 03:00) - Unraid stick config backed up to kraken ~/karma-flash-config-20261127.tgz (private: keys inside)
- [ ] label the drives with their pool names (table above)
- [ ] drives into kraken; boot; check every disk by serial (`lsblk -d -o NAME,SIZE,SERIAL`)
- [ ] read-only check: `sudo zpool import` (lists them), then per disk
      `sudo zpool import -f -o readonly=on diskN`, look at /mnt/diskN, then
      `sudo zpool export diskN` (all five)
- [x] `sudo karma-fixup` (after the LAST karma-copy; done 02:38, only seerr/settings.old.json left = harmless): rewrites .5 / gluetun ports in
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
- [x] public names on jpc.onl, routes on the kraken tunnel (done 2026-11-26):
      plex.jpc.onl -> localhost:32400 (no Access - Plex logs in itself; DIGI = CGNAT, so
      Tailscale first, tunnel as fallback; karma-fixup sets Plex's custom URL to it);
      seerr.jpc.onl -> localhost:5055 behind Access (the app's domain moved to jpc.onl).
      Seerr on karma stopped 2026-11-26; seerr.zulupapa.org route + DNS deleted.
- [x] move day: delete plex.zulupapa.org (route + DNS) on karma's tunnel (2026-11-27).
      Later: audiobookshelf.jpc.onl when ABS moves (Access domain + its OIDC redirect URLs)
- [ ] after: Immich + Audiobookshelf (separately); Phockup + Calibre (kept, set up later)
- [ ] Office VM (copied 2026-11-26, checksums match): kraken ~/office-vm = vdisk1.img
      (100G sparse, 19G used), Office.xml, NVRAM (UEFI vars). Set up with libvirt
      (myServices.libvirt), adapt OVMF paths/emulator/bridge; Windows may want reactivation
- [ ] port karma's User Scripts as systemd timers (keys in agenix): limited-backlog-search
      (every minute, alternating one Radarr/Sonarr missing-item search; karma used ports
      1070/1060 -> kraken 7878/8989) and fix-empty-year-folders (every 20 min, Sonarr "()"
      folders). vm.max_map_count was for Seafile - drop. (Their Radarr/Sonarr API keys
      showed up in a session log 2026-11-26 - rotate when convenient.)
- [ ] tunnel routes, kuro's mounts, PS5 to .5 later (LAN plan)

## 5. After

- [ ] originals on the array disks (home ~970G, backup ~327G, trading 374G) come along
      as a FALLBACK only - stale from move day (kuro's NFS uses the vault copies).
      After 1-2 weeks on kraken + a verification (sizes/file counts vs vault): delete
      them from disk1-5 -> ~1.7 TB free, the array media-only. Never write to them.
      (nvme-appdata, nvme-immich, ssd-downloads get wiped when they take their new roles.)
- [ ] SnapRAID with the old parity disk (no parity protection until the first sync)
- [ ] quarterly scrub for the media pool + its healthchecks check
- [x] delete karma-import.nix (2026-11-27)
- [ ] retire karma's Tailscale node; delete karma's Cloudflare tunnel (no routes left)
- [ ] keep the Unraid stick until kraken has run a few weeks
