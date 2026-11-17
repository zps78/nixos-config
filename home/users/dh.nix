# ../../home/users/dh.nix
#
# dh ("dharma" - karma's counterpart) on a headless server (karma): the
# admin account you SSH into.
# Deliberately lean - not like ./bb.nix, bb's workstation profile on krieger
# (Bambu Studio, Zed, Lutris, a niri session, ...), which a box with no
# screen doesn't need. Shell and CLI basics only.
{ pkgs, ... }:

{
  home.username                                  = "dh";
  home.homeDirectory                             = "/home/dh";
  home.stateVersion                              = "26.11";          # release this home was first set up with - never bump on upgrades

  home.packages = with pkgs; [
    htop                                 # process viewer
    ncdu                                 # disk usage browser
    tmux                                 # keep long jobs alive across SSH drops
  ];

  programs.bash.enable                           = true;
}
