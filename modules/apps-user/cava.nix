# ../../modules/apps-user/cava.nix
{ config, lib, ... }:

{
  options.myApps.cava.enable =
    lib.mkEnableOption "Cava";

  config = lib.mkIf config.myApps.cava.enable {
    programs.cava = {
      enable = true;

      # Load the Noctalia-generated theme (~/.config/cava/themes/noctalia).
      # Double-quoted so Noctalia's cava template apply.sh sees it already
      # set and skips rewriting this (read-only) config.
      settings.color.theme = ''"noctalia"'';
    };

    # cava errors if the theme file is missing; create a stub so the first
    # boot (before Noctalia renders) uses defaults instead of failing.
    home.activation.cavaNoctaliaPlaceholder =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        d="$HOME/.config/cava/themes"
        [ -e "$d/noctalia" ] || {
          $DRY_RUN_CMD mkdir -p "$d"
          $DRY_RUN_CMD printf '[color]\n' > "$d/noctalia"
        }
      '';
  };
}
