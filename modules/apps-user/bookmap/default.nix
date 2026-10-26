# ../../modules/apps-user/bookmap/default.nix
#
# Bookmap (bookmap.com) - not in nixpkgs. The tarball ships its own Temurin
# JRE, a prebuilt libpainter.so and JCEF (Chromium) that unpacks natives at
# runtime, so instead of patchelf-ing all that it runs unmodified inside an
# FHS env.
#
# Like sierrachart.nix, the pinned tarball only seeds a writable copy at
# ~/.local/share/bookmap/install on first launch, so Bookmap's in-app
# updater can replace its own files. After that bumping sources.json has no
# effect on an existing install - delete that folder to reseed. User state
# (settings, workspaces) lives separately in ~/.bookmap.
#
# sources.json pins each channel from the bookmap.com/current/<channel>/linux
# redirect (dl.bookmap.com URL, version, hash).
{ config, pkgs, lib, ... }:

let
  cfg = config.myApps.bookmap;
  source = (lib.importJSON ./sources.json).${cfg.channel};

  seed = pkgs.stdenvNoCC.mkDerivation {
    pname = "bookmap-seed";
    inherit (source) version;
    src = pkgs.fetchurl {
      inherit (source) url hash;
      name = "bookmap_install-${source.version}.tar.gz";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;
    dontFixup = true;                                  # leave the bundled JRE alone
    installPhase = ''
      mkdir -p $out/opt/bookmap
      tar -xzf $src -C $out/opt/bookmap
      unzip -p $out/opt/bookmap/Bookmap.jar resources/icons/logos/bookmap-0.png \
        > bookmap.png
      install -Dm644 bookmap.png $out/share/icons/hicolor/256x256/apps/bookmap.png
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "bookmap";
    desktopName = "Bookmap${lib.optionalString (cfg.channel != "production") " (${cfg.channel})"}";
    genericName = "Order flow trading platform";
    exec = "bookmap %u";
    icon = "bookmap";
    categories = [ "Office" "Finance" ];
    mimeTypes = [ "application/bmo" "application/bmf" "application/bmw" ];
    startupWMClass = "velox-ib-Main";
  };

  bookmap = pkgs.buildFHSEnv {
    pname = "bookmap";
    inherit (source) version;
    targetPkgs = p: with p; [
      stdenv.cc.cc.lib zlib glib alsa-lib fontconfig freetype dbus
      # AWT / Swing
      libx11 libxext libxrender libxtst libxi libxrandr libxcursor
      libxinerama libxxf86vm libxfixes libxcomposite libxdamage libxcb
      libxkbcommon libGL
      # JCEF (Chromium)
      nss nspr at-spi2-atk at-spi2-core atk cups expat gtk3 pango cairo
      libdrm libgbm libxshmfence systemd
    ];
    # niri / tiling: AWT draws blank windows without this
    profile = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    runScript = pkgs.writeShellScript "bookmap-run" ''
      dir="''${XDG_DATA_HOME:-$HOME/.local/share}/bookmap/install"

      if [[ ! -e $dir/bookmap_runscript.sh ]]; then
        mkdir -p "$dir"
        cp -r ${seed}/opt/bookmap/. "$dir"
        chmod -R u+w "$dir"
      fi

      # the desktop entry passes a bare path; Bookmap wants --file <path>
      if [[ $# -eq 1 && $1 != -* ]]; then set -- --file "$1"; fi
      exec "$dir/bookmap_runscript.sh" "$@"
    '';
    extraInstallCommands = ''
      install -Dm644 ${seed}/share/icons/hicolor/256x256/apps/bookmap.png \
        $out/share/icons/hicolor/256x256/apps/bookmap.png
      install -Dm644 ${./bookmap-types.xml} $out/share/mime/packages/bookmap-types.xml
    '';
  };
in
{
  options.myApps.bookmap = {
    enable = lib.mkEnableOption "Bookmap";
    channel = lib.mkOption {
      type = lib.types.enum [ "production" "beta" ];
      default = "production";
      description = "Release channel to seed a fresh install from (must have an entry in sources.json).";
    };
  };

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf cfg.enable {
    home.packages = [ bookmap ];

    # Bookmap writes its own (NoDisplay, raw-runscript Exec) bookmap.desktop
    # and mime package into ~/.local/share on every launch, which would
    # shadow this entry in the launcher. Owning both paths as read-only HM
    # symlinks makes its write fail harmlessly ("Failed to register file
    # extensions"). Not xdg.desktopEntries: that installs into the profile,
    # which ~/.local/share/applications still overrides.
    xdg.dataFile."applications/bookmap.desktop".source = "${desktopItem}/share/applications/bookmap.desktop";
    xdg.dataFile."mime/packages/bookmap-types.xml".source = ./bookmap-types.xml;
  };
}
