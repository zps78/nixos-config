# ../../home/profiles/server.nix
#
# Lean profile for an admin account on a machine whose desktop (if any)
# belongs to someone else: shell and CLI basics only, no desktop apps.
# Used by zp on kimi (whose session is gt's) and on kraken (headless).
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

  # Same prompt layout as the desktops (home/common.nix), in gruvbox dark:
  # there's no Noctalia here to colour it. dotfiles/oh-my-posh/server.json
  # is the Noctalia template (dotfiles/noctalia/templates/oh-my-posh.json)
  # with each {{ colors.<role> }} turned into a palette reference (p:<role>)
  # and a gruvbox "palette" block - swap colours there, not in the
  # segments. Plus user@host in the session segment, so an SSH prompt
  # shows which machine it's on.
  programs.bash.initExtra = ''
    eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init bash --config ${../../dotfiles/oh-my-posh/server.json})"
  '';
}
