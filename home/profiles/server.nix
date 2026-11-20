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
    oh-my-posh                           # prompt, same look as the desktops (below)
    htop                                 # process viewer
    ncdu                                 # disk usage browser
    tmux                                 # keep long jobs alive across SSH drops
  ];

  programs.bash.enable                           = true;

  # Same prompt as the desktops (home/common.nix), but from a fixed copy of
  # the theme: there's no Noctalia here to regenerate it on theme changes.
  # dotfiles/oh-my-posh/server.json is a snapshot of the desktops'
  # generated quick-term.json, with user@host in the session segment so an
  # SSH prompt shows which machine it's on. Re-snapshot it from a desktop's
  # ~/.config/oh-my-posh/quick-term.json after a Noctalia theme change.
  programs.bash.initExtra = ''
    eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init bash --config ${../../dotfiles/oh-my-posh/server.json})"
  '';
}
