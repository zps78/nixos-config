# ../../modules/apps-user/browser-extensions.nix
#
# Shared browser extension set. NOT a module - imported explicitly by the
# browser app modules:
#
#   import ./browser-extensions.nix firefoxAddons.firefox-addons
#
# firefox.nix and zen-browser.nix consume this directly (rycee
# firefox-addons packages). brave.nix uses Chrome Web Store IDs and keeps
# its own list in sync by hand.

firefox-addons:

let
  # Not in rycee's set - packaged straight from AMO. Bump version/url/hash
  # from https://addons.mozilla.org/api/v5/addons/addon/remote-torrent-adder16/
  # (current_version.file.{url,hash}). Its WebUI host/port/credentials are
  # set in the extension's Options page (extension storage, not Nix).
  remote-torrent-adder = firefox-addons.buildFirefoxXpiAddon {
    pname = "remote-torrent-adder";
    version = "2.4.1";
    addonId = "remote-torrent-adder@bogenpirat";
    url = "https://addons.mozilla.org/firefox/downloads/file/5183267/remote_torrent_adder16-2.4.1.xpi";
    sha256 = "sha256-OYCHof7tXIo2gDlFUhxMQfEVlxLYX+N12qXxblR+H+w=";
    meta = {
      homepage = "https://addons.mozilla.org/firefox/addon/remote-torrent-adder16/";
      description = "Send torrent and magnet links to a remote torrent client's WebUI";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
in

with firefox-addons; [
  ublock-origin
  sponsorblock
  keepa
  proton-pass
  print-edit-we
  video-downloadhelper
  consent-o-matic
  dearrow
  ff2mpv                       # native host: ff2mpv-rust, wired in each browser module
  sonarr-radarr-lidarr-search
  remote-torrent-adder
]
