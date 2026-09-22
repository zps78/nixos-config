# ../../modules/apps-user/nautilus.nix
#
# GNOME Files. Network/NFS browsing (gvfs) is already provided
# unconditionally elsewhere - see modules/services/gvfs.nix.
#
# Thumbnails are NOT covered by common.nix's kdePackages.ffmpegthumbs /
# kdegraphics-thumbnailers - those are KDE's own KIO ThumbnailCreator
# plugins, a KDE-specific plugin ABI Dolphin loads directly, not the
# freedesktop.org .thumbnailer files GNOME/Nautilus's GIO thumbnailing
# actually reads (confirmed: PDFs had no thumbnail in Nautilus despite
# working fine in Dolphin). evince and ffmpegthumbnailer below ship the
# real .thumbnailer files for PDFs and video respectively.
#
# Same root cause for zip/xlsx showing generic icons instead of proper
# ones: common.nix only installs adw-gtk3 (a GTK3 *widget style* port
# of libadwaita, not an icon theme), so there was no icon theme with
# real MIME coverage installed for GTK apps at all - confirmed Dolphin
# shows these fine (Breeze has the coverage), Nautilus didn't.
# adwaita-icon-theme below fixes that, and matches adw-gtk3's own
# aesthetic rather than pulling in a mismatched theme like Papirus.
#
# 3mf (Bambu Studio/Orca Slicer project files) has no thumbnailer
# anywhere - not a KDE or GNOME default, and no nixpkgs package
# provides one. It doesn't need one: a .3mf is a zip archive and Orca
# already embeds a rendered PNG preview inside it at a known path, so
# extracting it is enough - no actual 3D rendering needed. Tries the
# core-3MF-spec path first, falls back to Orca's own plate_1.png
# convention (confirmed via https://danb.me/blog/3mf-gnome-thumbnails/).
{ config, pkgs, lib, ... }:

let
  threeMfThumbnailer = pkgs.writeShellApplication {
    name = "3mf-thumbnailer";
    runtimeInputs = [ pkgs.unzip ];
    text = ''
      input="$1"
      output="$2"
      if ! unzip -p "$input" "Metadata/thumbnail.png" > "$output" 2>/dev/null || [ ! -s "$output" ]; then
        unzip -p "$input" "Metadata/plate_1.png" > "$output" 2>/dev/null || true
      fi
      [ -s "$output" ]
    '';
  };
in
{
  options.myApps.nautilus.enable =
    lib.mkEnableOption "Nautilus (GNOME Files)";

  config = lib.mkIf config.myApps.nautilus.enable {
    home.packages = with pkgs; [
      nautilus
      evince               # ships the GNOME/freedesktop .thumbnailer for PDFs
      ffmpegthumbnailer    # ships the GNOME/freedesktop .thumbnailer for video
      adwaita-icon-theme   # generic MIME icons (zip, xlsx, etc.) for GTK apps
      threeMfThumbnailer
    ];

    xdg.dataFile."thumbnailers/3mf.thumbnailer".text = ''
      [Thumbnailer Entry]
      Exec=${threeMfThumbnailer}/bin/3mf-thumbnailer %i %o
      MimeType=application/vnd.ms-3mfdocument;model/3mf;
    '';
  };
}
