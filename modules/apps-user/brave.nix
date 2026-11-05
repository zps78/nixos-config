# ../../modules/apps-user/brave.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.brave.enable =
    lib.mkEnableOption "Brave Browser";

  config = lib.mkIf config.myApps.brave.enable {
    programs.brave = {
      enable = true;

      # Chrome Web Store IDs. Firefox equivalents live in
      # ./browser-extensions.nix - keep this list roughly in sync.
      # (No uBlock: Brave has built-in adblock. No real torrent-control
      # equivalent - Remote Torrent Adder below is the closest fit, but
      # it intercepts matching page links rather than registering as a
      # magnet: protocol handler, and needs its own WebUI host/port/
      # credentials entered in its Options page - that's extension
      # storage, not something this file or a policy can set.)
      # ff2mpv extension -> mpv
      nativeMessagingHosts = [ pkgs.ff2mpv-rust ];

      extensions = [
        "mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock
        "neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
        "ghmbeldphafepmbegfdlkpapadhbakde"  # Proton Pass
        "olnblpmehglpcallpnbgmikjblmkopia"  # Print Edit WE
        "lmjnegcaeklhafolokijcfjliaokphfk"  # Video DownloadHelper
        "mdjildafknihdffpkfmmpnpoiajfjnjd"  # Consent-O-Matic
        "oabphaconndgibllomdcjbfdghcmenci"  # Remote Torrent Adder
        "enamippconapkdmgfgjchkhakpfinmaj"  # DeArrow
        "ephjcajbkgplkjmelpglennepbpmdpjg"  # ff2mpv
        "jmmjjcddjldjdjgckdiokhfokccdnekc"  # Sonarr/Radarr/Lidarr autosearch
      ];
    };

    # The package ships a second, NoDisplay copy of its desktop entry
    # (com.brave.Browser.desktop, kept for the XDG portal app id) with the
    # same MimeType list, so Brave showed up twice in "Open With". Drop the
    # copy's associations; brave-browser.desktop keeps them.
    xdg.mimeApps.associations.removed = lib.genAttrs [
      "application/pdf" "application/rdf+xml" "application/rss+xml"
      "application/xhtml+xml" "application/xhtml_xml" "application/xml"
      "image/gif" "image/jpeg" "image/png" "image/webp"
      "text/html" "text/xml"
      "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/chromium"
    ] (_: [ "com.brave.Browser.desktop" ]);
  };
}
