# ../../home/mime.nix
#
# Default-application associations. App-specific blocks are gated on the
# matching myApps.*.enable so a user who hasn't enabled an app never gets
# a default handler pointing at a missing .desktop file.
{ config, lib, ... }:

let
  app = config.myApps;

  gwenview = "org.kde.gwenview.desktop";
  dolphin = "org.kde.dolphin.desktop";
  ark = "org.kde.ark.desktop";
  darktable = "org.darktable.darktable.desktop";
  kate = "org.kde.kate.desktop";
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

      # ----- always available (unconditional KDE app set in common.nix) -----

      (forEach gwenview [
        "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif"
        "image/heif" "image/bmp" "image/tiff" "image/svg+xml" "image/jxl"
      ])

      {
        "application/pdf"                = "okularApplication_pdf.desktop";
        "application/epub+zip"           = "okularApplication_epub.desktop";
        "application/x-mobipocket-ebook" = "okularApplication_mobi.desktop";
        "application/x-cbz"              = "okularApplication_comicbook.desktop";
        "application/x-cbr"              = "okularApplication_comicbook.desktop";
        "application/x-cbt"              = "okularApplication_comicbook.desktop";
        "application/x-cb7"              = "okularApplication_comicbook.desktop";

        "inode/directory"               = dolphin;

        "application/zip"                = ark;
        "application/x-tar"              = ark;
        "application/x-compressed-tar"   = ark;
        "application/x-7z-compressed"    = ark;
        "application/vnd.rar"            = ark;
      }

      # ----- RAW photographs -----

      (lib.mkIf app.darktable.enable (forEach darktable [
        "image/x-adobe-dng" "image/x-canon-cr2" "image/x-canon-cr3"
        "image/x-canon-crw" "image/x-nikon-nef" "image/x-nikon-nrw"
        "image/x-olympus-orf" "image/x-panasonic-rw" "image/x-panasonic-rw2"
        "image/x-pentax-pef" "image/x-sony-arw" "image/x-sony-sr2"
        "image/x-sony-srf"
      ]))

      # ----- text / code -----

      (lib.mkIf app.kate.enable (forEach kate [
        "text/plain" "text/markdown" "text/x-nix" "text/xml"
        "application/vnd.kdl"
      ]))

      # ----- web -----

      (lib.mkIf app.zen-browser.enable (forEach zen [
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
