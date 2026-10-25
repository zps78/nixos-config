# ../../modules/apps-user/sierrachart.nix
#
# Sierra Chart (Windows-only) under Wine. It's a portable app that writes
# Data/, chartbooks and its own updates into its install folder, so it can't
# run from the store: the pinned zip below only seeds a dedicated prefix
# (~/.local/share/sierrachart/prefix, program in C:\SierraChart) on first
# launch. After that Sierra Chart updates itself (Help > Download Currently
# Released Version) and bumping `build` here has no effect on an existing
# install - delete the prefix to reseed from a newer zip.
#
# Zip list: https://www.sierrachart.com/index.php?page=doc/SCZipInstallerList.php
{ config, pkgs, lib, ... }:

let
  build = "2976";

  zip = pkgs.fetchurl {
    url = "https://download1.sierrachart.com/downloads/ZipFiles/SierraChart${build}.zip";
    hash = "sha256-FpZ/QGGb5UjR6P0KmsrueG4oHRduGCPzyns4p/lHmUc=";
  };

  # same Wine as modules/apps-system/wine.nix, so no second copy in the closure
  wine = pkgs.wineWow64Packages.staging;

  launcher = pkgs.writeShellApplication {
    name = "sierrachart";
    runtimeInputs = [ wine pkgs.unzip pkgs.coreutils ];
    text = ''
      export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/sierrachart/prefix"
      export WINEDEBUG=-all
      # no wine-generated menu entries / file associations next to ours
      export WINEDLLOVERRIDES="winemenubuilder.exe=d"
      dir="$WINEPREFIX/drive_c/SierraChart"

      if [[ ! -e $dir/SierraChart_64.exe ]]; then
        mkdir -p "$WINEPREFIX"
        # native C++ app: skip the interactive Wine Mono / Gecko installers
        WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree,mshtml=" wineboot --init
        wineserver --wait
        mkdir -p "$dir"
        unzip -q -o ${zip} -d "$dir"
        chmod -R u+w "$dir"
      fi

      cd "$dir"
      exec wine SierraChart_64.exe "$@"
    '';
  };

  icons = pkgs.runCommand "sierrachart-icons" { nativeBuildInputs = [ pkgs.unzip pkgs.icoutils ]; } ''
    unzip -q ${zip} SierraChart_64.exe
    wrestool -x -t 14 SierraChart_64.exe > sc.ico
    icotool -x sc.ico
    for png in sc_*.png; do
      size=$(echo "$png" | sed -E 's/.*_([0-9]+)x[0-9]+x[0-9]+\.png/\1/')
      install -Dm644 "$png" $out/share/icons/hicolor/''${size}x''${size}/apps/sierrachart.png
    done
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = "sierrachart";
    desktopName = "Sierra Chart";
    genericName = "Trading and charting platform";
    exec = "sierrachart";
    icon = "sierrachart";
    categories = [ "Office" "Finance" ];
    startupWMClass = "sierrachart_64.exe";
  };
in
{
  options.myApps.sierrachart.enable =
    lib.mkEnableOption "Sierra Chart (Wine)";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.sierrachart.enable {
    home.packages = [ launcher icons desktopItem ];
  };
}
