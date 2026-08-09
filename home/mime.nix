# ../../home/mime.nix
{ ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # ==========================
      # Images
      # ==========================

      "image/jpeg"                     = "org.kde.gwenview.desktop";
      "image/png"                      = "org.kde.gwenview.desktop";
      "image/gif"                      = "org.kde.gwenview.desktop";
      "image/webp"                     = "org.kde.gwenview.desktop";
      "image/avif"                     = "org.kde.gwenview.desktop";
      "image/heif"                     = "org.kde.gwenview.desktop";
      "image/bmp"                      = "org.kde.gwenview.desktop";
      "image/tiff"                     = "org.kde.gwenview.desktop";
      "image/svg+xml"                  = "org.kde.gwenview.desktop";
      "image/jxl"                      = "org.kde.gwenview.desktop";

      # ==========================
      # RAW photographs
      # ==========================

      "image/x-adobe-dng"              = "org.darktable.darktable.desktop";
      "image/x-canon-cr2"              = "org.darktable.darktable.desktop";
      "image/x-canon-cr3"              = "org.darktable.darktable.desktop";
      "image/x-canon-crw"              = "org.darktable.darktable.desktop";
      "image/x-nikon-nef"              = "org.darktable.darktable.desktop";
      "image/x-nikon-nrw"              = "org.darktable.darktable.desktop";
      "image/x-olympus-orf"            = "org.darktable.darktable.desktop";
      "image/x-panasonic-rw"           = "org.darktable.darktable.desktop";
      "image/x-panasonic-rw2"          = "org.darktable.darktable.desktop";
      "image/x-pentax-pef"             = "org.darktable.darktable.desktop";
      "image/x-sony-arw"               = "org.darktable.darktable.desktop";
      "image/x-sony-sr2"               = "org.darktable.darktable.desktop";
      "image/x-sony-srf"               = "org.darktable.darktable.desktop";

      # ==========================
      # Documents
      # ==========================

      "application/pdf"                = "okularApplication_pdf.desktop";
      "application/epub+zip"           = "okularApplication_epub.desktop";
      "application/x-mobipocket-ebook" = "okularApplication_mobi.desktop";

      # Comics
      "application/x-cbz"              = "okularApplication_comicbook.desktop";
      "application/x-cbr"              = "okularApplication_comicbook.desktop";
      "application/x-cbt"              = "okularApplication_comicbook.desktop";
      "application/x-cb7"              = "okularApplication_comicbook.desktop";

      # ==========================
      # Text / configuration / code
      # ==========================

      "text/plain"                     = "org.kde.kate.desktop";
      "text/markdown"                  = "org.kde.kate.desktop";
      "text/x-nix"                     = "org.kde.kate.desktop";
      "text/xml"                       = "org.kde.kate.desktop";

      # KDL — MIME type provided by our declarative KDL definition
      "application/vnd.kdl"            = "org.kde.kate.desktop";

      # ==========================
      # Microsoft Office
      # ==========================

      "application/msword"                                         = "onlyoffice-desktopeditors.desktop";
      "application/msword-template"                                = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-word.document.macroEnabled.12"           = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-word.template.macroEnabled.12"           = "onlyoffice-desktopeditors.desktop";

      "application/vnd.ms-excel"                                   = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel.sheet.macroEnabled.12"             = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel.sheet.binary.macroEnabled.12"      = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel.template.macroEnabled.12"          = "onlyoffice-desktopeditors.desktop";

      "application/vnd.ms-powerpoint"                              = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"    = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-powerpoint.template.macroEnabled.12"     = "onlyoffice-desktopeditors.desktop";

      # ==========================
      # Microsoft / OpenXML Office
      # ==========================
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"      = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template"      = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"            = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template"         = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"    = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow"       = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.template"        = "onlyoffice-desktopeditors.desktop";

      # ==========================
      # OpenDocument
      # ==========================
      "application/vnd.oasis.opendocument.text"                    = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text-template"           = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet"             = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet-template"    = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation"            = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation-template"   = "onlyoffice-desktopeditors.desktop";

      # Other common office formats
      "text/csv"                       = "onlyoffice-desktopeditors.desktop";
      "text/tab-separated-values"      = "onlyoffice-desktopeditors.desktop";
      "application/rtf"                = "onlyoffice-desktopeditors.desktop";

      # ==========================
      # Audio
      # ==========================
      "audio/mpeg"                     = "mpv.desktop";
      "audio/mp4"                      = "mpv.desktop";
      "audio/m4a"                      = "mpv.desktop";
      "audio/flac"                     = "mpv.desktop";
      "audio/ogg"                      = "mpv.desktop";
      "audio/wav"                      = "mpv.desktop";
      "audio/x-wav"                    = "mpv.desktop";
      "audio/aac"                      = "mpv.desktop";
      "audio/opus"                     = "mpv.desktop";
      "audio/ac3"                      = "mpv.desktop";
      "audio/eac3"                     = "mpv.desktop";
      "audio/webm"                     = "mpv.desktop";

      # ==========================
      # Video
      # ==========================
      "video/mp4"                      = "mpv.desktop";
      "video/x-matroska"               = "mpv.desktop";
      "video/mkv"                      = "mpv.desktop";
      "video/webm"                     = "mpv.desktop";
      "video/mpeg"                     = "mpv.desktop";
      "video/avi"                      = "mpv.desktop";
      "video/x-avi"                    = "mpv.desktop";
      "video/x-msvideo"                = "mpv.desktop";
      "video/quicktime"                = "mpv.desktop";
      "video/x-flv"                    = "mpv.desktop";
      "video/x-ms-wmv"                 = "mpv.desktop";
      "video/ogg"                      = "mpv.desktop";
      "video/3gp"                      = "mpv.desktop";

      # ==========================
      # IPTV / playlists
      # ==========================
      "application/x-mpegurl"          = "iptvnator.desktop";
      "application/vnd.apple.mpegurl"  = "iptvnator.desktop";
      "audio/mpegurl"                  = "iptvnator.desktop";
      "audio/x-mpegurl"                = "iptvnator.desktop";
    };
  };
}
