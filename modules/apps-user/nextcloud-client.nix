# ../../modules/apps-user/nextcloud-client.nix
#
# Nextcloud desktop sync client for kraken's https://cloud.jpc.onl
# (tailnet/LAN only for now). Runs as a systemd user service with the
# graphical session, starting minimised to the tray. The login is kept in
# the Secret Service (gnome-keyring on niri). Account and folders are set
# up in the client itself (~/.config/Nextcloud), not here.
#
# Offloading: put files in the synced folder, let them upload, then untick
# the folder in "Choose what to sync" - the local copy goes, the server
# keeps it. (Virtual files are still experimental on Linux.)
{ config, pkgs, lib, ... }:

{
  options.myApps.nextcloud-client.enable =
    lib.mkEnableOption "Nextcloud desktop sync client";

  config = lib.mkIf config.myApps.nextcloud-client.enable {
    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
