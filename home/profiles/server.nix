# ../../home/profiles/server.nix
#
# Lean profile for an admin account on a machine whose desktop (if any)
# belongs to someone else: shell and CLI basics only, no desktop apps.
# Used by zp on kimi (whose session is gt's) and on karma (headless).
# Username/home come from makeUser in flake.nix.
{ pkgs, lib, ... }:

{
  home.stateVersion                              = lib.mkDefault "26.11"; # release this home was first set up with - never bump on upgrades

  home.packages = with pkgs; [
    htop                                 # process viewer
    ncdu                                 # disk usage browser
    tmux                                 # keep long jobs alive across SSH drops
  ];

  programs.bash.enable                           = true;
}
