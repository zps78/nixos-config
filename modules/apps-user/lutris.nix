# ../../modules/apps-user/lutris.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.lutris.enable =
    lib.mkEnableOption "Lutris";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.lutris.enable {
    home.packages = [
      # steamSupport is for importing/launching Steam-owned games from
      # inside Lutris's UI - not used here. Steam is the primary library
      # (modules/apps-system/steam.nix); Lutris only manages a few local
      # titles, surfaced into Steam via its own "Add to Steam" /
      # Non-Steam-Game entry. Dropping it saves ~2GB of bundled Steam
      # with no functional loss for that workflow.
      (pkgs.lutris.override {
        steamSupport = false;

        # Lutris's FHS sandbox doesn't bundle GameMode at all (confirmed
        # against nixpkgs' own package.nix - no mention of it in either
        # targetPkgs or multiPkgs, unlike e.g. its full GStreamer set).
        # NixOS's own programs.gamemode.enable (see
        # modules/apps-system/steam.nix) installs the daemon and library
        # to the system profile fine, but that's invisible from inside
        # the sandbox - confirmed via `gamemodeauto: dlopen failed -
        # libgamemode.so: cannot open shared object file` in a real
        # game's log on krieger despite gamemoded genuinely running.
        # extraLibraries bridges it in the same way bottles.nix's own
        # gstreamer/etc. deps already work.
        extraLibraries = pkgs: [ pkgs.gamemode.lib ];
      })
    ];
  };
}
