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
# either). meld/pinta are included too since they're general tools with
# no desktop-stack reasoning behind them - niri.nix having them isn't a
# reason for GNOME to lack them.
#
# The grey-folder icon theme (niri.nix's Adwaita-Grey-Folders,
# home/lib/adwaita-grey-folders.nix) is deliberately NOT ported here -
# it existed to fix a blue-folder visual clash specific to niri's own
# theming, not something GNOME has, so GNOME just uses whatever Stylix
# (modules/desktop/gnome.nix) generates for its icon target instead.
#
# NOT ported from niri.nix: the qt6ct Noctalia-theming patch (Noctalia
# doesn't run on GNOME), Noctalia's own settings block, the niri-specific
# idle-monitor script and output/input/debug.kdl sourcing, and the
# greeter-wallpaper hook (tied to Noctalia's template-engine hook system,
# which GNOME/gdm has no equivalent of - GNOME's wallpaper-driven
# theming instead comes from Stylix, see modules/desktop/gnome.nix).
{ pkgs, ... }:

{
  imports = [
    ./gnome-keybinds.nix
    ./gnome-paperwm.nix
    ./gnome-blur-my-shell.nix
  ];

  home.packages = with pkgs; [
    file-roller   # Archive manager - not in GNOME's core-apps bundle
    foliate       # E-book reader (epub/mobi/azw3) - papers doesn't cover these

    meld          # Visual diff and merge tool
    pinta         # Drawing/editing program modeled after Paint.NET
  ];

  # Pure-Wayland setup (GNOME on Wayland, same as niri) with no X11
  # session at all. Stylix's xresources target (only exists at this
  # home-manager level, not the NixOS system level - see
  # modules/desktop/gnome.nix) tries to reload via `xrdb` during
  # activation regardless of session type, which fails hard ("Can't
  # open display ':0'") and aborts the WHOLE home-manager activation,
  # not just that one target - confirmed via a live failed switch.
  # x11 disabled for the same reason (X-specific root-window settings,
  # meaningless with no X server running).
  stylix.targets.xresources.enable = false;
  stylix.targets.x11.enable = false;
}
