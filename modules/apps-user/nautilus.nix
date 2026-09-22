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
# 3D model thumbnails (stl/obj/ply/gltf/3mf/step/...) come from f3d
# (modules/apps-user/f3d.nix), which ships real .thumbnailer files
# covering all of that - true for every current niri user (f3d.enable
# is true in every home/users/*.nix). A custom extraction-based 3mf
# thumbnailer used to live here too, before f3d's own coverage was
# noticed - dropped to avoid two thumbnailers registered for the same
# model/3mf mime type, and f3d's is a real render of current content
# rather than whatever was embedded at export time.
{ config, pkgs, lib, ... }:

{
  options.myApps.nautilus.enable =
    lib.mkEnableOption "Nautilus (GNOME Files)";

  config = lib.mkIf config.myApps.nautilus.enable {
    home.packages = with pkgs; [
      nautilus
      evince               # ships the GNOME/freedesktop .thumbnailer for PDFs
      ffmpegthumbnailer    # ships the GNOME/freedesktop .thumbnailer for video
      adwaita-icon-theme   # generic MIME icons (zip, xlsx, etc.) for GTK apps
    ];
  };
}
