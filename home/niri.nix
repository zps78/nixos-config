# ../../home/niri.nix
#
# niri + Noctalia specific home config. Shared/desktop-agnostic bits live
# in ./common.nix. Imported only when osConfig.myDesktop.stack == "niri".
{ lib, pkgs, config, osConfig, ... }:

{
  # ===========================================================================
  # Noctalia (bar / shell / theme generator)
  # ===========================================================================

  programs.noctalia = {
    enable = true;
    settings = {
      # Native themed polkit agent (replaces polkit-gnome). Needed for the
      # greeter appearance-sync prompt among other things.
      shell.polkit_agent = true;
    }
    // lib.optionalAttrs osConfig.myDesktop.idle.enable {
      # Idle: lock, then blank, then suspend. (logind still handles lid
      # close; lockscreen.lock_before_suspend handles lock-on-suspend.)
      idle = {
        behavior_order = [ "lock" "screen-off" "suspend" ];
        behavior = {
          lock         = { timeout = 600;  action = "lock";             enabled = true; };
          "screen-off" = { timeout = 660;  action = "screen_off";       enabled = true; };
          suspend      = { timeout = 1800; action = "lock_and_suspend"; enabled = true; };
        };
      };
    };
  };

  # While >1 output is connected (docked / external displays), inhibit
  # idle via Noctalia caffeine; release it back to a single screen. Runs
  # as a niri child (spawn-at-startup) so it inherits $NIRI_SOCKET.
  # Edge-triggered so it doesn't fight a manual caffeine toggle.
  xdg.configFile."niri/scripts/idle-monitor.sh" = lib.mkIf osConfig.myDesktop.idle.enable {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      niri=${pkgs.niri}/bin/niri
      jq=${pkgs.jq}/bin/jq
      noctalia=${lib.getExe config.programs.noctalia.package}
      state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/niri-idle-monitor.state"

      while :; do
        n=$("$niri" msg -j outputs 2>/dev/null | "$jq" 'length' 2>/dev/null || echo "")
        case "$n" in
          ""|*[!0-9]*) ;;   # no/garbled reading - skip this round
          *)
            if [ "$n" -gt 1 ]; then want=1; else want=0; fi
            if [ "$want" != "$(cat "$state" 2>/dev/null || echo x)" ]; then
              printf '%s' "$want" > "$state"
              if [ "$want" = 1 ]; then
                "$noctalia" msg caffeine-enable  >/dev/null 2>&1 || true
              else
                "$noctalia" msg caffeine-disable >/dev/null 2>&1 || true
              fi
            fi
            ;;
        esac
        sleep 20
      done
    '';
  };

  # ===========================================================================
  # App <-> Noctalia theme wiring
  # ===========================================================================
  #
  # Noctalia generates the themes; these connect specific apps to them.

  # niri: config.kdl (in dotfiles/) has `include "noctalia.kdl"`; make sure
  # the file exists so niri doesn't error on a missing include before
  # Noctalia first renders it.
  home.activation.niriNoctaliaPlaceholder =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/niri"
      [ -e "$HOME/.config/niri/noctalia.kdl" ] || \
        $DRY_RUN_CMD touch "$HOME/.config/niri/noctalia.kdl"
    '';

  # ghostty
  programs.ghostty.settings.theme = "noctalia";

  # kate
  home.activation.kateNoctaliaTheme =
    lib.mkIf config.myApps.kate.enable
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/katerc" \
          --group "UiSettings" \
          --key "ColorScheme" \
          "noctalia"
      '');

  # qt6ct (only rewrites an existing conf; first run needs qt6ct launched once)
  home.activation.qt6ctNoctaliaTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      qt6ct_conf="$HOME/.config/qt6ct/qt6ct.conf"

      if [ -f "$qt6ct_conf" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed \
          -i \
          -e "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/noctalia.conf|" \
          -e "s|^standard_dialogs=.*|standard_dialogs=xdgdesktopportal|" \
          "$qt6ct_conf"
      fi
    '';

  # ===========================================================================
  # Tiling-WM app behaviour
  # ===========================================================================

  # No CSD min/max/close buttons under a tiling compositor.
  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
    };
  };

  # Hide KDE System Settings from menus (not used on niri).
  xdg.dataFile."applications/systemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  xdg.dataFile."applications/kdesystemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  # ===========================================================================
  # Greeter wallpaper hook
  # ===========================================================================
  #
  # Fired by the Noctalia template engine on wallpaper/theme change (see
  # dotfiles/noctalia/templates.toml). Blurs + tints the current wallpaper
  # to match the lock screen's [lockscreen] blur_intensity / tint_intensity
  # / blurred_desktop, and writes /var/lib/greeter-wallpaper/login.png,
  # which noctalia-greeter reads on the next login. No rebuild needed.

  xdg.configFile."noctalia/hooks/greeter-blur.sh" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -euo pipefail

      wallpaper="''${1:-}"
      surface="''${2:-#000000}"
      # ''${3:-} is the theme mode; unused for now.

      out="/var/lib/greeter-wallpaper/login.png"
      res="2560x1440"
      blur_scale="20"   # ImageMagick sigma per unit of blur_intensity; tune to match

      magick="${pkgs.imagemagick}/bin/magick"
      yq="${pkgs.yq-go}/bin/yq"

      state_toml="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
      conf_toml="''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"

      [ -n "$wallpaper" ] && [ -r "$wallpaper" ] || exit 0
      [ -w "$(dirname "$out")" ] || exit 0

      read_key() {   # $1 = dotted key, $2 = default
        local f v
        for f in "$state_toml" "$conf_toml"; do
          [ -r "$f" ] || continue
          v=$("$yq" -p toml -oy -r ".$1" "$f" 2>/dev/null || true)
          if [ -n "$v" ] && [ "$v" != "null" ]; then printf '%s' "$v"; return; fi
        done
        printf '%s' "$2"
      }

      blurred=$(read_key 'lockscreen.blurred_desktop' 'false')
      bi=$(read_key 'lockscreen.blur_intensity' '0.5')
      ti=$(read_key 'lockscreen.tint_intensity' '0.3')

      if [ "$blurred" = "true" ]; then
        sigma=$(awk -v b="$bi" -v s="$blur_scale" 'BEGIN { printf "%.2f", b * s }')
      else
        sigma=0
      fi
      tint_pct=$(awk -v t="$ti" 'BEGIN { printf "%d", (t * 100) + 0.5 }')

      tmp=$(mktemp "$out.XXXXXX")
      trap 'rm -f "$tmp"' EXIT

      args=( "$wallpaper" -auto-orient -resize "$res^" -gravity center -extent "$res" )
      if awk -v s="$sigma" 'BEGIN { exit !(s + 0 > 0) }'; then
        args+=( -blur "0x$sigma" )
      fi
      args+=( -fill "$surface" -colorize "$tint_pct%" "png:$tmp" )

      "$magick" "''${args[@]}"
      chmod 0644 "$tmp"
      mv -f "$tmp" "$out"
    '';
  };

  # ===========================================================================
  # niri configuration (from dotfiles/)
  # ===========================================================================

  xdg.configFile = {
    "niri/animations.kdl".source                  = ../dotfiles/niri/animations.kdl;
    "niri/binds.kdl".source                       = ../dotfiles/niri/binds.kdl;
    "niri/config.kdl".source                      = ../dotfiles/niri/config.kdl;
    "niri/cursor.kdl".source                      = ../dotfiles/niri/cursor.kdl;
    "niri/decorations.kdl".source                 = ../dotfiles/niri/decorations.kdl;
    "niri/input.kdl".source                       = ../dotfiles/niri/input.kdl;
    "niri/layout.kdl".source                      = ../dotfiles/niri/layout.kdl;
    "niri/spawn-at-startup.kdl".source            = ../dotfiles/niri/spawn-at-startup.kdl;
    "niri/window-rules.kdl".source                = ../dotfiles/niri/window-rules.kdl;
    "niri/output.kdl".source                      = ../hosts/${osConfig.networking.hostName}/niri/output.kdl;

    "noctalia/templates.toml".source              = ../dotfiles/noctalia/templates.toml;
    "noctalia/templates/oh-my-posh.json".source   = ../dotfiles/noctalia/templates/oh-my-posh.json;
  };
}
