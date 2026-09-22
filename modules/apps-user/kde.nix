# ../../modules/apps-user/kde.nix
#
# Standalone KDE apps - archiver, document viewer, image viewer - plus the
# qt6ct patch that lets Noctalia theme them. Split out of common.nix when
# dolphin was removed in favour of nautilus: these don't depend on dolphin
# in any way, they just used to sit in the same "KDE" package group.
#
# kdePackages.ffmpegthumbs / kdegraphics-thumbnailers (dolphin's own KIO
# ThumbnailCreator plugins) were dropped entirely, not moved here - they
# were dolphin-specific and nothing else in this config uses them; the
# freedesktop.org .thumbnailer equivalents nautilus actually needs live in
# nautilus.nix instead.
{ config, pkgs, lib, ... }:

{
  options.myApps.kde.enable =
    lib.mkEnableOption "KDE app set (Ark, Okular, Gwenview)";

  config = lib.mkIf config.myApps.kde.enable {
    home.packages = with pkgs; [
      kdePackages.ark        # File archiver by KDE
      kdePackages.gwenview   # Image viewer by KDE
      kdePackages.okular     # KDE document viewer
      # partitionmanager lives in modules/system/packages.nix, not here -
      # it needs to be a system package for its polkit action to be
      # visible at all (see the comment there).

      # qt6ct patched (from the AUR qt6ct-kde package) so it reads KDE
      # color schemes / KF6 config - lets Noctalia theme Qt/KDE apps
      # through ~/.config/qt6ct. Patch vendored to avoid an eval-time
      # fetch from aur.archlinux.org.
      (kdePackages.qt6ct.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          ../../home/patches/qt6ct-noctalia-theming.patch
        ];
      }))
    ];
  };
}
