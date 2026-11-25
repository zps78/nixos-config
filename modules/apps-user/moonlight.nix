# ../../modules/apps-user/moonlight.nix
#
# Moonlight follows the Noctalia colour scheme. Moonlight forces Qt's
# Material style (dark), but lets QT_QUICK_CONTROLS_MATERIAL_{ACCENT,PRIMARY,
# FOREGROUND,...} override its defaults - except the window background,
# which main.qml hard-codes to #303030. So:
#   - patch: drop that one line (Material.background then comes from the
#     environment like the rest);
#   - wrapper: at every start, read ~/.config/noctalia/colors.json and set
#     the variables (a scheme change applies from the next launch). Without
#     the file it falls back to Moonlight's own look.
# Cost: Moonlight is built from source (substitutes no longer match).
{ config, pkgs, lib, ... }:

let
  moonlight-patched = pkgs.moonlight-qt.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace app/gui/main.qml \
        --replace-fail 'Material.background = "#303030"' ""
    '';
  });

  moonlight-themed = pkgs.symlinkJoin {
    name = "moonlight-qt-noctalia-${moonlight-patched.version}";
    paths = [ moonlight-patched ];
    postBuild = ''
      rm $out/bin/moonlight
      cat > $out/bin/moonlight <<'EOF'
      #!${pkgs.runtimeShell}
      c="''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/colors.json"
      get() { [ -r "$c" ] && ${pkgs.jq}/bin/jq -r --arg k "$1" '.[$k] // empty' "$c" 2>/dev/null; }
      bg=$(get mSurface); fg=$(get mOnSurface); bar=$(get mSurfaceVariant); acc=$(get mPrimary)
      export QT_QUICK_CONTROLS_MATERIAL_BACKGROUND="''${bg:-#303030}"
      [ -n "$fg" ]  && export QT_QUICK_CONTROLS_MATERIAL_FOREGROUND="$fg"
      [ -n "$bar" ] && export QT_QUICK_CONTROLS_MATERIAL_PRIMARY="$bar"
      [ -n "$acc" ] && export QT_QUICK_CONTROLS_MATERIAL_ACCENT="$acc"
      exec ${moonlight-patched}/bin/moonlight "$@"
      EOF
      chmod +x $out/bin/moonlight
    '';
  };
in
{
  options.myApps.moonlight.enable = lib.mkEnableOption "Moonlight";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.moonlight.enable {
    home.packages = [ moonlight-themed ];
  };
}
