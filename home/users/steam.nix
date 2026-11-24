# ../../home/users/steam.nix
#
# kraken's unprivileged session account: Sunshine streaming and Steam
# (in gamescope, started on demand). Admin work happens as zp over SSH;
# this user has no wheel, no docker and no password (see
# hosts/kraken/configuration.nix).
# Kept deliberately lean - games and a few things you'd use from the
# couch, not bb's workstation apps.
{ lib, osConfig, ... }:

{
  home.username                                  = "steam";
  home.homeDirectory                             = "/home/steam";
  home.stateVersion                              = "25.11";          # release this home was first set up with - never bump on upgrades

  # No niri/Noctalia: this account's session is Steam in gamescope
  # (myDesktop.streamApps on kraken). Noctalia's user service hangs
  # off graphical-session.target and would just crash-loop without a
  # compositor it can talk to.
  imports = [
    ../../modules/apps-user
    ../common.nix
  ];

  myApps = {
    # gaming (Steam itself is the system myFeatures.steam feature)
    lutris.enable                                = true;             # Open Source gaming platform for GNU/Linux
    bottles.enable                               = true;             # Easy-to-use wineprefix manager

    # couch basics
    mpv.enable                                   = true;             # Media player
    brave.enable                                 = true;             # Browser (store logins, guides)

    # The "Zen (VPN)" Sunshine app (myDesktop.streamApps.zen) runs this
    # profile, full-screen in cage, inside the AirVPN namespace.
    zen-browser.enable                           = osConfig.myDesktop.streamApps.zen.enable;
  };

  # Zen behind the VPN: only the tunnel's DNS (no DNS over HTTPS around it),
  # no local addresses leaked through WebRTC, hardware video decode on.
  # Added on top of the shared policies/prefs in modules/apps-user/zen-browser.nix.
  programs.zen-browser = lib.mkIf osConfig.myDesktop.streamApps.zen.enable {
    policies.DNSOverHTTPS = { Enabled = false; Locked = true; };
    profiles.default.settings = {
      # Always private ("permanent private browsing"): no history, cookies
      # and site data dropped when Zen closes. Bookmarks are still kept.
      "browser.privatebrowsing.autostart"              = true;
      # Natural ("reversed") scrolling, like kuro's touchpad. Moonlight sends
      # scrolling as plain wheel steps, and Moonlight for Android (Shield) has
      # no reverse option - so flip it in Zen, for every client. (Moonlight
      # PC's "Reverse mouse scrolling direction" must then stay OFF.)
      "mousewheel.default.delta_multiplier_y"          = -100;
      "network.trr.mode"                               = 5;      # DoH off, explicitly
      "media.peerconnection.ice.default_address_only"  = true;   # WebRTC: no host/LAN candidates
      "media.peerconnection.ice.no_host"               = true;
      "media.ffmpeg.vaapi.enabled"                     = true;   # VA-API (nvidia-vaapi-driver)
      "media.hardware-video-decoding.force-enabled"    = true;
      "widget.dmabuf.force-enabled"                    = true;
    };
  };
}
