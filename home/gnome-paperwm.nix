# ../../home/gnome-paperwm.nix
#
# PaperWM: a GNOME Shell "scrollable tiling" extension - the same
# lineage niri itself draws from (infinite horizontal scroll of
# columns), unlike a BSP/split-tree tiler such as Forge. Checked
# directly against its real schema: most of niri's own key choices
# (Mod+Left/Right/Up/Down + HJKL, Mod+Home/End, Mod+Shift+arrows for
# monitor focus, Mod+R for width presets, even Mod+Minus/Equal for
# resize) already match PaperWM's own defaults, not by luck - both
# extensions are built around the same "scrolling columns" mental
# model. No maintenance red flag either: declares support up to shell-
# version 50 (matches what nixpkgs ships) and a long version history
# (148), unlike Forge's stale 50.1 ceiling and "needs a new maintainer"
# notice.
#
# PaperWM also reworks workspace navigation as part of its scrolling
# model, so the sequential workspace-left/right binds below are left to
# PaperWM's own equivalents rather than GNOME's native wm.keybindings
# (see the removed switch/move-to-workspace-left/right keys in
# gnome-keybinds.nix) - binding the same combo in two competing
# mechanisms is asking for undefined behaviour, not redundancy.
{ pkgs, ... }:

{
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.paperwm; }
    ];
  };

  dconf.settings."org/gnome/shell/extensions/paperwm/keybindings" = {
    # ----- Exact matches to PaperWM's own defaults - restated
    # explicitly (not left implicit) so an extension update can't
    # silently change them, with niri's HJKL aliases added where niri
    # dual-binds arrows and letters and PaperWM's default doesn't -----
    switch-left  = [ "<Super>Left"  "<Super>h" ];  # niri: focus-column-left
    switch-right = [ "<Super>Right" "<Super>l" ];  # niri: focus-column-right
    switch-up    = [ "<Super>Up"    "<Super>k" ];  # niri: focus-window-up
    switch-down  = [ "<Super>Down"  "<Super>j" ];  # niri: focus-window-down

    move-left  = [ "<Super><Ctrl>Left"  "<Super><Ctrl>h" ];  # niri: move-column-left
    move-right = [ "<Super><Ctrl>Right" "<Super><Ctrl>l" ];  # niri: move-column-right
    move-up    = [ "<Super><Ctrl>Up"    "<Super><Ctrl>k" ];  # niri: move-window-up
    move-down  = [ "<Super><Ctrl>Down"  "<Super><Ctrl>j" ];  # niri: move-window-down

    switch-first = [ "<Super>Home" ];  # niri: focus-column-first
    switch-last  = [ "<Super>End" ];   # niri: focus-column-last

    switch-monitor-left  = [ "<Super><Shift>Left"  "<Super><Shift>h" ];  # niri: focus-monitor-left
    switch-monitor-right = [ "<Super><Shift>Right" "<Super><Shift>l" ];  # niri: focus-monitor-right
    switch-monitor-above = [ "<Super><Shift>Up"    "<Super><Shift>k" ];  # niri: focus-monitor-up
    switch-monitor-below = [ "<Super><Shift>Down"  "<Super><Shift>j" ];  # niri: focus-monitor-down

    move-monitor-left  = [ "<Super><Shift><Ctrl>Left"  "<Super><Shift><Ctrl>h" ];  # niri: move-column-to-monitor-left
    move-monitor-right = [ "<Super><Shift><Ctrl>Right" "<Super><Shift><Ctrl>l" ];  # niri: move-column-to-monitor-right
    move-monitor-above = [ "<Super><Shift><Ctrl>Up"    "<Super><Shift><Ctrl>k" ];  # niri: move-column-to-monitor-up
    move-monitor-below = [ "<Super><Shift><Ctrl>Down"  "<Super><Shift><Ctrl>j" ];  # niri: move-column-to-monitor-down

    # niri: Mod+Page_Up/Down and Mod+U/I (focus-workspace-up/down) -
    # PaperWM's own default is Page_Up/Down only, U/I added to match
    # niri's dual binding.
    switch-up-workspace   = [ "<Super>Page_Up"   "<Super>u" ];
    switch-down-workspace = [ "<Super>Page_Down" "<Super>i" ];
    # niri: Mod+Ctrl+Page_Up/Down and Mod+Ctrl+U/I (move-column-to-workspace-*)
    move-up-workspace   = [ "<Super><Ctrl>Page_Up"   "<Super><Ctrl>u" ];
    move-down-workspace = [ "<Super><Ctrl>Page_Down" "<Super><Ctrl>i" ];

    # niri: switch-preset-column-width / -back (Mod+R / Mod+Shift+R).
    # PaperWM's own cycle-width already defaults to <Super>r; its
    # cycle-width-backwards default (<Super><Alt>r) moved to
    # <Super><Shift>r to match niri's modifier choice instead.
    cycle-width           = [ "<Super>r" ];
    cycle-width-backwards = [ "<Super><Shift>r" ];
    # niri: switch-preset-window-height (Mod+Ctrl+Shift+R). PaperWM's
    # cycle-height defaulted to <Super><Shift>r, freed above - moved
    # here to match niri's key instead.
    cycle-height = [ "<Super><Ctrl><Shift>r" ];
    # cycle-height-backwards left on PaperWM's own default
    # (<Super><Alt><Shift>r) - niri has no "cycle height back" action,
    # only reset-window-height, which isn't the same thing.

    # niri: center-column (Mod+C). PaperWM's center-horizontally is a
    # closer semantic match than Forge's fixed-geometry snap ever was -
    # both are "center this column", not "center this floating window".
    # Already PaperWM's own default, restated for stability.
    center-horizontally = [ "<Super>c" ];

    # niri: toggle-window-floating (Mod+V). PaperWM calls this "scratch"
    # (attach/detach a window from tiling into a floating layer) - the
    # real equivalent, not a literal float-toggle action name. Moved
    # from its own default (<Super><Ctrl>Escape) to match niri's key;
    # center-vertically (PaperWM's own default on <Super>v, for
    # floating/non-tiled windows specifically) is cleared below since
    # niri has nothing to map it to and it would collide.
    toggle-scratch = [ "<Super>v" ];
    center-vertically = [ ];

    # niri: consume-window-into-column / expel-window-from-column
    # (Mod+Comma / Mod+Period). PaperWM's own summaries for these are
    # near word-for-word matches to niri's ("consume window into the
    # active column" / "expel the bottom window into its own column").
    # Moved from their own defaults (<Super>i / <Super>o) to match
    # niri's keys; switch-next/switch-previous (PaperWM's own defaults
    # on period/comma) are cleared below since they'd otherwise collide
    # and niri has nothing equivalent to preserve there instead.
    slurp-in  = [ "<Super>comma" ];   # niri: consume-window-into-column
    barf-out  = [ "<Super>period" ];  # niri: expel-window-from-column
    switch-next     = [ ];
    switch-previous = [ ];
    # niri's Mod+BracketLeft/Right (consume-or-expel-window-left/right,
    # a single context-sensitive bind) has no PaperWM equivalent - left
    # entirely alone. PaperWM's own drift-left/drift-right already live
    # on those exact bracket keys by default, for a genuinely different
    # PaperWM-specific feature (scrolling the viewport without moving
    # focus) - not touched, no reason to fight over the keys.

    # niri: maximize-column (Mod+F) - "expand this column to fill
    # available width" is exactly what toggle-maximize-width does.
    # Already PaperWM's own default, restated for stability.
    toggle-maximize-width = [ "<Super>f" ];

    # niri: fullscreen-window (Mod+Shift+F). PaperWM's own
    # paper-toggle-fullscreen already defaults to this exact combo -
    # used instead of GNOME's native toggle-fullscreen (removed from
    # gnome-keybinds.nix) since PaperWM needs to know about fullscreen
    # transitions to correctly restore tiling state afterward.
    paper-toggle-fullscreen = [ "<Super><Shift>f" ];

    # niri: set-column-width/set-window-height +/-10% (Mod+Minus/Equal,
    # Mod+Shift+Minus/Equal). PaperWM's own resize-w-*/resize-h-* already
    # default to these exact combos - restated for stability, not moved.
    resize-w-dec = [ "<Super>minus" ];
    resize-w-inc = [ "<Super>plus" ];
    resize-h-dec = [ "<Super><Shift>minus" ];
    resize-h-inc = [ "<Super><Shift>plus" ];

    # niri: Mod+Return opens the Terminal custom keybinding (see
    # gnome-keybinds.nix) - PaperWM's own new-window default
    # (<Super>Return AND <Super>n) collided on the Return half; only
    # that accelerator removed, <Super>n kept for PaperWM's own
    # "open another window of the focused app" feature.
    new-window = [ "<Super>n" ];
  };

  # ----- No PaperWM equivalent at all - not attempted -----
  # niri's move-column-to-first/last (Mod+Ctrl+Home/End - PaperWM has
  # no "move to first/last position" action, only the switch-* focus
  # equivalents mapped above); expand-column-to-available-width
  # (Mod+Ctrl+F); center-visible-columns (Mod+Ctrl+C - PaperWM's centers
  # a single window, not "all visible columns", different enough not to
  # force); toggle-column-tabbed-display (Mod+W - PaperWM is a pure
  # horizontal-scroll model with no tabbed/stacked column display mode
  # at all, unlike niri or Forge); switch-focus-between-floating-and-
  # tiling (Mod+Shift+V).
}
