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

with firefox-addons; [
  ublock-origin
  sponsorblock
  keepa
  proton-pass
  print-edit-we
  video-downloadhelper
  consent-o-matic
  torrent-control
]
