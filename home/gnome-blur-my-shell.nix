# ../../home/gnome-blur-my-shell.nix
#
# Blur My Shell: adds frosted-glass blur to GNOME Shell's own panel and
# Activities Overview. The GNOME answer to "a launcher that looks/feels
# like Noctalia" - reskins the native overview (Mod key, same as niri's
# toggle-overview) rather than fighting a non-native launcher into
# GNOME (wofi and friends need wlr-layer-shell, which Mutter doesn't
# support - confirmed via wofi's own docs, it just crashes without
# --normal-window there, and even then loses the overlay feel).
#
# Healthy maintenance signals, same check as PaperWM/Forge: declares
# support up to shell-version 50 (matches what nixpkgs ships) with a
# long version history (72).
#
# Blur is on by default for both overview and panel; the only override
# here is switching both from their "light" default style to "dark"
# plus a light tint, to roughly match Noctalia's own dark-mode +
# tinted-glass look (niri.nix: theme.mode = "dark",
# backdrop.tint_intensity = 0.3) - not a guaranteed numeric match
# across two different blur implementations, just a reasonable
# starting point. Fine-tune live afterward via the extension's own
# preferences UI (GNOME Extensions app, or `gnome-extensions prefs
# blur-my-shell@aunetx`) rather than guessing more values blind here.
{ pkgs, lib, ... }:

let
  # The schema's `color` key is a GVariant tuple (dddd), not a plain
  # array - needs home-manager's gvariant helper or dconf writes the
  # wrong type entirely.
  mkTuple = lib.hm.gvariant.mkTuple;
in
{
  programs.gnome-shell.extensions = [
    { package = pkgs.gnomeExtensions.blur-my-shell; }
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      style-components = 2;  # 0 not styled, 1 light, 2 dark, 3 transparent
      customize = true;
      color = mkTuple [ 0.0 0.0 0.0 0.3 ];  # matches Noctalia's tint_intensity 0.3
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      style-panel = 2;  # 0 transparent, 1 light, 2 dark, 3 contrasted
      customize = true;
      color = mkTuple [ 0.0 0.0 0.0 0.3 ];
    };
  };
}
