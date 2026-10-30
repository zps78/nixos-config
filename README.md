-:1:-
BIOS: disable secure boot

-:2:-
NixOS install

-:3:-
sudo nano /etc/nixos/configuration.nix:
  + packages:
      git

-:4:-
sudo nixos-rebuild switch
cd ~
git clone https://github.com/zps78/nixos-config.git
sudo nixos-rebuild switch --flake .#kuro

-:5:-
IPTVnator playlist
  http://iptv-org.github.io/iptv/index.m3u

-:6:-
TODO - pending decisions for Claude

[ ] noctalia plugins: try the official ones manually, then say which to
    pin in programs.noctalia.settings ([plugins].enabled). Candidates:
      - screen-recorder   needs pkg gpu-screen-recorder (OBS is disabled)
      - translator / timer / world-clock   no deps
      - wallhaven   needs network
      - video-wallpaper   needs pkg mpvpaper + mpv
      - wallpaper-depth / bongo-cat
[ ] desktop + lockscreen widgets: frameworks are enabled but empty.
    Decide a layout (per-monitor x/y) or keep placing them in the GUI.
[ ] SierraChart: once installed, give Claude the SDK include path (the
    folder with sierrachart.h) to add a .clangd/compile_flags.txt so
    clangd gets real completion/diagnostics on ACSIL studies, not just
    generic C++ highlighting.

Manual setup (no repo change):
[ ] Proton Calendar: Proton has no CalDAV (confirmed 2026-10-29, despite
    what this note used to say - do not retry that path). Instead: in
    Proton Calendar, open the calendar -> Share -> Share with anyone ->
    create a link; then Noctalia Settings -> Calendar -> Add Account ->
    ICS URL -> paste that link. No credentials needed, read-only, syncs
    on Noctalia's own refresh_minutes interval.
[ ] Brave Browser: per-profile GUI toggles, no managed policy or
    programs.brave option exists for any of these (confirmed 2026-10-30)
    - redo on each user's own profile after a fresh Brave install:
      - GTK theme: brave://settings/appearance -> theme -> GTK. Gives
        exact-match theming with other GTK apps (literal paint), unlike
        the BrowserThemeColor policy approach (tried and reverted - only
        seeds Chromium's own theme generator, can't match exactly).
      - uBlock Origin: brave://settings/extensions/v2 -> toggle it on.
        Google pulled MV2 extensions from the Chrome Web Store (Aug
        2026); Brave self-hosts uBlock Origin there instead - full
        version, not the gimped MV3 "Lite". Brave Shields alone misses
        some popups (e.g. on 1337x) that uBlock catches.
      - Vertical tabs: right-click a tab -> Show vertical tabs (or
        brave://settings/appearance). Native Chromium feature.
      - Backspace = back (like Zen): brave://settings/system/shortcuts
        -> rebind Back to Backspace. Chrome removed this by default
        years ago; Brave's custom shortcuts page can restore it.
      - Remote Torrent Adder extension: open its Options page, point it
        at karma's qBittorrent WebUI (LAN host/port, no SSL - see
        Sonarr/Radarr's download client config for the current value),
        enter credentials, enable Link Catching so it auto-intercepts
        magnet/torrent links instead of requiring a manual right-click
        each time. Connection details live in the extension's own
        storage, not something a policy file can set.
[ ] After rebuild to noctalia 5.1: check `systemctl --user status
    noctalia` and eyeball the bar for shifted runtime defaults.
