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
[ ] After rebuild to noctalia 5.1: check `systemctl --user status
    noctalia` and eyeball the bar for shifted runtime defaults.
