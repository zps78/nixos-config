# ../../home/gnome.nix
#
# GNOME-specific home config. Shared/desktop-agnostic bits live in
# ./common.nix. Imported only when osConfig.myDesktop.stack == "gnome".
#
# Deliberately slim: modules/desktop/gnome.nix turns on
# services.desktopManager.gnome, which pulls in nixpkgs's own GNOME
# core-apps bundle (nautilus, papers, loupe, baobab, gnome-disk-utility,
# gnome-calculator, adwaita-icon-theme, gst-thumbnailers/glycin-thumbnailer
# for video+image thumbnails, and more) automatically - none of that is
# redone here. This file only adds what that bundle genuinely doesn't
# cover, confirmed by reading the actual module source rather than
# assuming: file-roller (no bundled archive manager), foliate (no
# bundled ebook reader - papers/evince never covered epub/mobi/azw3
# either), and the same grey-folder icon theme niri.nix uses (desktop-
# agnostic, just not GNOME's default). meld/pinta are included too since
# they're general tools with no desktop-stack reasoning behind them -
# niri.nix having them isn't a reason for GNOME to lack them.
#
# NOT ported from niri.nix: the qt6ct Noctalia-theming patch (Noctalia
# doesn't run on GNOME), Noctalia's own settings block, the niri-specific
# idle-monitor script and output/input/debug.kdl sourcing, and the
# greeter-wallpaper hook (tied to Noctalia's template-engine hook system,
# which GNOME/gdm has no equivalent of).
{ pkgs, ... }:

let
  adwaitaGreyFolders = pkgs.callPackage ./lib/adwaita-grey-folders.nix { };
in
{
  home.packages = with pkgs; [
    file-roller   # Archive manager - not in GNOME's core-apps bundle
    foliate       # E-book reader (epub/mobi/azw3) - papers doesn't cover these
    adwaitaGreyFolders

    meld          # Visual diff and merge tool
    pinta         # Drawing/editing program modeled after Paint.NET
  ];

  dconf.settings."org/gnome/desktop/interface" = {
    # Adwaita-Grey-Folders (defined above) - Inherits=Adwaita, so
    # everything except the folder icons is unchanged real Adwaita.
    # Unlike niri (gtk.enable = false there, Noctalia manages GTK
    # theming its own way), GNOME's own gtk.iconTheme mechanism would
    # also work here, but setting the same dconf key directly keeps
    # this file consistent with niri.nix's approach.
    icon-theme = "Adwaita-Grey-Folders";
  };
}
