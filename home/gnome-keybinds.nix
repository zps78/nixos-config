# ../../home/gnome-keybinds.nix
#
# Declarative GNOME keybindings - the dconf/gsettings equivalent of
# dotfiles/niri/binds.kdl. GNOME has no text config file for this at
# all; every bind is a key in a gsettings schema, set here via dconf.
# Verified every key name below against the real installed schemas
# (gsettings-desktop-schemas, gnome-settings-daemon, gnome-shell)
# rather than assuming - a wrong dconf key name doesn't error, it just
# silently does nothing.
#
# Matched 1:1 to binds.kdl's Mod (= Super here) combos wherever GNOME
# has a real equivalent. Deliberately NOT attempted: anything built on
# niri's tiling "column" concept (move-column-*, consume/expel,
# preset widths, floating toggle, tabbed display, center-column,
# monitor-directional focus/move) - none of that exists in stock
# GNOME/Mutter, which isn't a tiling WM. Would need a Shell extension
# (Pop Shell, Forge) to get any of it back - a separate decision, not
# attempted here.
{ ... }:
{
  dconf.settings = {
    # "Run this command" binds - a *list* of dconf paths, each with its
    # own name/command/binding under its own key below. Commands run
    # directly (no shell), so anything needing shell features (here:
    # $HOME expansion) is wrapped in sh -c, same reason binds.kdl uses
    # spawn-sh instead of spawn for the same two binds.
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
      ];

      # GNOME's own default is <Super>l - overridden to match niri's
      # Mod+Alt+L for muscle-memory parity across both machines.
      screensaver = [ "<Super><Alt>l" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name    = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name    = "File Manager";
      command = "sh -c 'xdg-open $HOME'";
      binding = "<Super>e";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name    = "Default Browser";
      command = "xdg-open http://";
      binding = "<Super>b";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name    = "Zed";
      command = "zeditor";
      binding = "<Super>z";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      # gnome-session-quit's own confirmation dialog, matching binds.kdl's
      # note that niri's quit action "will show a confirmation dialog to
      # avoid accidental exits".
      name    = "Session Quit";
      command = "gnome-session-quit";
      binding = "<Super><Shift>e";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close            = [ "<Super>q" ];  # niri: Mod+Q
      toggle-maximized = [ "<Super>m" ];  # niri: Mod+M (maximize-window-to-edges)
      # niri's Mod+F (maximize-column) has no native-GNOME equivalent -
      # tiling-only, covered by home/gnome-paperwm.nix's
      # toggle-maximize-width instead when PaperWM is in use.
      #
      # toggle-fullscreen deliberately left unset here - when PaperWM
      # is in use (home/gnome-paperwm.nix) it owns Mod+Shift+F instead,
      # since it needs to know about fullscreen transitions to restore
      # tiling state correctly afterward. Without PaperWM this means
      # Mod+Shift+F does nothing until GNOME's own default binding (if
      # any) or a manual override fills it back in.

      # Workspace-by-number - niri: Mod+1..9 / Mod+Ctrl+1..9
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];

      move-to-workspace-1 = [ "<Super><Control>1" ];
      move-to-workspace-2 = [ "<Super><Control>2" ];
      move-to-workspace-3 = [ "<Super><Control>3" ];
      move-to-workspace-4 = [ "<Super><Control>4" ];
      move-to-workspace-5 = [ "<Super><Control>5" ];
      move-to-workspace-6 = [ "<Super><Control>6" ];
      move-to-workspace-7 = [ "<Super><Control>7" ];
      move-to-workspace-8 = [ "<Super><Control>8" ];
      move-to-workspace-9 = [ "<Super><Control>9" ];

      # Sequential workspace switching (niri: Mod+Page_Up/Down, Mod+U/I)
      # deliberately NOT set here - when PaperWM is in use
      # (home/gnome-paperwm.nix) it reworks workspace navigation as
      # part of its own scrolling model and owns these combos instead;
      # binding the same keys in both places risks undefined behaviour
      # rather than harmless redundancy. Without PaperWM, these combos
      # are simply unbound until set some other way.
    };

    "org/gnome/shell/keybindings" = {
      # show-screenshot-ui opens GNOME's interactive picker (region or
      # window or full, with annotation) - closest single match to
      # niri's Print (Noctalia screenshot-region). screenshot is an
      # instant, no-UI full screenshot - matches niri's Ctrl+Print.
      show-screenshot-ui = [ "Print" ];
      screenshot          = [ "<Control>Print" ];

      # toggle-overview is left at GNOME's own default (plain Super) -
      # it's already the native equivalent of niri's Mod+Space
      # toggle-overview, no override needed.
    };
  };
}
