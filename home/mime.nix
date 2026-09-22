# ../../home/mime.nix
#
# Default-application associations. App-specific blocks are gated on the
# matching myApps.*.enable so a user who hasn't enabled an app never gets
# a default handler pointing at a missing .desktop file. The GNOME-
# ecosystem block below is gated on osConfig.myDesktop.stack instead,
# since those apps (home/niri.nix) have no myApps.*.enable of their own -
# always-on for every niri host, not something meant to vary per user.
{ config, lib, osConfig, ... }:

let
  app = config.myApps;
  isNiri = osConfig.myDesktop.stack == "niri";

  loupe = "org.gnome.Loupe.desktop";
  evince = "org.gnome.Evince.desktop";
  foliate = "com.github.johnfactotum.Foliate.desktop";
  fileRoller = "org.gnome.FileRoller.desktop";
  nautilus = "org.gnome.Nautilus.desktop";
  darktable = "org.darktable.darktable.desktop";
  zed = "dev.zed.Zed.desktop";
  zen = "zen-beta.desktop";
  office = "onlyoffice-desktopeditors.desktop";
  mpv = "mpv.desktop";
  iptvnator = "iptvnator.desktop";

  forEach = handler: types: lib.genAttrs types (_: handler);
in
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = lib.mkMerge [

      # ----- GNOME-ecosystem app set (niri only) -----
      # Replaces the old dolphin-era KDE set. evince covers pdf plus every
      # comic-book format okular did (and more: djvu, postscript, xps) -
      # but drops epub/mobi entirely, hence foliate picking those up
      # separately. Verified each app's real MimeType coverage against its
      # own .desktop file rather than assuming.

      (lib.mkIf isNiri (forEach loupe [
        "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif"
        "image/heic" "image/bmp" "image/tiff" "image/svg+xml" "image/jxl"
      ]))

      (lib.mkIf isNiri {
        "application/pdf"                    = evince;
        "application/x-cbz"                  = evince;
        "application/x-cbr"                  = evince;
        "application/x-cbt"                  = evince;
        "application/x-cb7"                  = evince;
        "image/vnd.djvu"                     = evince;
        "application/postscript"             = evince;
        "application/oxps"                   = evince;

        "application/epub+zip"               = foliate;
        "application/x-mobipocket-ebook"     = foliate;
        "application/vnd.amazon.mobi8-ebook" = foliate;

        "application/zip"                    = fileRoller;
        "application/x-tar"                  = fileRoller;
        "application/x-compressed-tar"       = fileRoller;
        "application/x-7z-compressed"        = fileRoller;
        "application/vnd.rar"                = fileRoller;

        "inode/directory"                    = nautilus;
      })

      # ----- RAW photographs -----

      (lib.mkIf app.darktable.enable (forEach darktable [
        "image/x-adobe-dng" "image/x-canon-cr2" "image/x-canon-cr3"
        "image/x-canon-crw" "image/x-nikon-nef" "image/x-nikon-nrw"
        "image/x-olympus-orf" "image/x-panasonic-rw" "image/x-panasonic-rw2"
        "image/x-pentax-pef" "image/x-sony-arw" "image/x-sony-sr2"
        "image/x-sony-srf"
      ]))

      # ----- text / code -----

      (lib.mkIf app.zed.enable (forEach zed [
        "text/plain" "text/markdown" "text/x-nix" "text/xml"
        "application/toml" "application/vnd.kdl"
      ]))

      # ----- web -----
      # Falls back through whichever browser is actually enabled, rather
      # than hardcoding one - a user with e.g. zen-browser disabled (bb
      # on krieger, stripped down for gaming/streaming) still ends up
      # with a real default instead of no association at all, which is
      # what happened here before this fell back to nothing.
      (let
        defaultBrowser =
          if      app.zen-browser.enable then zen
          else if app.brave.enable       then "brave-browser.desktop"
          else if app.firefox.enable     then "firefox.desktop"
          else null;
      in lib.mkIf (defaultBrowser != null) (forEach defaultBrowser [
        "text/html" "x-scheme-handler/http" "x-scheme-handler/https"
        "x-scheme-handler/about" "x-scheme-handler/unknown"
      ]))

      # ----- office documents -----

      (lib.mkIf app.office.enable (forEach office [
        "application/msword"
        "application/msword-template"
        "application/vnd.ms-word.document.macroEnabled.12"
        "application/vnd.ms-word.template.macroEnabled.12"
        "application/vnd.ms-excel"
        "application/vnd.ms-excel.sheet.macroEnabled.12"
        "application/vnd.ms-excel.sheet.binary.macroEnabled.12"
        "application/vnd.ms-excel.template.macroEnabled.12"
        "application/vnd.ms-powerpoint"
        "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
        "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"
        "application/vnd.ms-powerpoint.template.macroEnabled.12"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        "application/vnd.openxmlformats-officedocument.presentationml.template"
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.text-template"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.spreadsheet-template"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.oasis.opendocument.presentation-template"
        "text/csv"
        "text/tab-separated-values"
        "application/rtf"
      ]))

      # ----- audio / video -----

      (lib.mkIf app.mpv.enable (forEach mpv [
        "audio/mpeg" "audio/mp4" "audio/m4a" "audio/flac" "audio/ogg"
        "audio/wav" "audio/x-wav" "audio/aac" "audio/opus" "audio/ac3"
        "audio/eac3" "audio/webm"
        "video/mp4" "video/x-matroska" "video/mkv" "video/webm"
        "video/mpeg" "video/avi" "video/x-avi" "video/x-msvideo"
        "video/quicktime" "video/x-flv" "video/x-ms-wmv" "video/ogg"
        "video/3gp"
      ]))

      # ----- IPTV / playlists -----

      (lib.mkIf app.iptvnator.enable (forEach iptvnator [
        "application/x-mpegurl" "application/vnd.apple.mpegurl"
        "audio/mpegurl" "audio/x-mpegurl"
      ]))
    ];
  };
}
