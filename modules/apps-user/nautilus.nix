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
{ config, pkgs, lib, ... }:

{
  options.myApps.nautilus.enable =
    lib.mkEnableOption "Nautilus (GNOME Files)";

  config = lib.mkIf config.myApps.nautilus.enable {
    home.packages = with pkgs; [
      nautilus
      evince              # ships the GNOME/freedesktop .thumbnailer for PDFs
      ffmpegthumbnailer   # ships the GNOME/freedesktop .thumbnailer for video
    ];
  };
}
