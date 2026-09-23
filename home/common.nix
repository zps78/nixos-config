# ../../home/common.nix
#
# Shared home config for every user: shell, terminal, mime associations
# and a baseline of GUI tools. Desktop-agnostic - the niri/Noctalia-
# specific bits (including its GNOME app set) live in ./niri.nix.
{ pkgs, ... }:

{
  imports = [
    ./mime.nix
  ];

  # ===========================================================================
  # Applications
  # ===========================================================================

  home.packages = with pkgs; [
    # CLI
    oh-my-posh                           # Prompt theme engine for any shell (see programs.bash below)

    # GTK
    adw-gtk3                             # Unofficial GTK 3 port of libadwaita
  ];

  # ===========================================================================
  # Terminal
  # ===========================================================================

  programs.ghostty = {
    enable = true;

    # Wrap the binary so GTK_IM_MODULE=simple applies to ghostty's own GTK
    # process on every launch path (keybind, Noctalia launcher, .desktop),
    # not just the niri bind. Fixes rendering/input of some special
    # characters. --set-default so it can still be overridden at launch.
    package = pkgs.symlinkJoin {
      name = "ghostty-im-wrapped";
      paths = [ pkgs.ghostty ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ghostty --set-default GTK_IM_MODULE simple
      '';
      # symlinkJoin drops meta; restore mainProgram so lib.getExe resolves.
      meta.mainProgram = "ghostty";
    };

    settings = {
      cursor-style = "block";
      shell-integration-features = "no-cursor";
      scrollback-limit = 50000000;
      mouse-hide-while-typing = true;

      # Terminal translucency. Fades only the background, not the text.
      # (niri has no compositor blur, so this won't be frosted.)
      background-opacity = 0.92;
    };
  };

  # ===========================================================================
  # Shell prompt
  # ===========================================================================
  #
  # oh-my-posh, themed from ~/.config/oh-my-posh/quick-term.json which
  # Noctalia regenerates from its template on theme changes.
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init bash --config "$HOME/.config/oh-my-posh/quick-term.json")"
    '';
  };
}
