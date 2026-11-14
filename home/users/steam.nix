# ../../home/users/steam.nix
#
# krieger's unprivileged desktop account: autologin, Sunshine streaming
# and Steam. Admin work happens as bb over SSH; this user has no wheel,
# no docker and no password (see hosts/krieger/configuration.nix).
# Kept deliberately lean - games and a few things you'd use from the
# couch, not bb's workstation apps.
{ lib, osConfig, ... }:

{
  home.username                                  = "steam";
  home.homeDirectory                             = "/home/steam";
  home.stateVersion                              = "25.11";

  # No niri/Noctalia: this account's session is Steam in gamescope
  # (myDesktop.steamGamescope on krieger). Noctalia's user service hangs
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
  };
}
