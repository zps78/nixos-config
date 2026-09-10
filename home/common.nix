# ../../home/common.nix
#
# Shared home config for every user: shell, terminal, the KDE app set,
# mime associations and a baseline of GUI tools. Desktop-agnostic - the
# niri/Noctalia-specific bits live in ./niri.nix.
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
    oh-my-posh                           # Prompt theme engine (see programs.bash below)

    # GTK
    adw-gtk3                             # Unofficial GTK 3 port of libadwaita

    # KDE
    kdePackages.ark                      # File archiver by KDE
    kdePackages.dolphin                  # File manager by KDE
    kdePackages.ffmpegthumbs             # FFmpeg-based thumbnail creator for video files
    kdePackages.gwenview                 # Image viewer by KDE
    kdePackages.kdegraphics-thumbnailers # Thumbnailers for various graphics file formats
    kdePackages.okular                   # KDE document viewer
    kdePackages.partitionmanager         # Manage disk devices, partitions and file systems

    # qt6ct patched (from the AUR qt6ct-kde package) so it reads KDE
    # color schemes / KF6 config - lets Noctalia theme Qt/KDE apps
    # through ~/.config/qt6ct. Patch vendored to avoid an eval-time
    # fetch from aur.archlinux.org.
    (kdePackages.qt6ct.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        ./patches/qt6ct-noctalia-theming.patch
      ];
    }))

    # Other GUI
    meld                                 # Visual diff and merge tool
    pinta                                # Drawing/editing program modeled after Paint.NET
    qdirstat                             # Graphical disk usage analyzer
    usbimager                            # Minimal GUI to write compressed disk images to USB
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
