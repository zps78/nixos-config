# ../../home/niri.nix
#
# niri + Noctalia specific home config. Shared/desktop-agnostic bits live
# in ./common.nix. Imported only when osConfig.myDesktop.stack == "niri".
{ lib, pkgs, config, osConfig, ... }:

{
  # ===========================================================================
  # Noctalia (bar / shell / theme generator)
  # ===========================================================================

  programs.noctalia.enable = true;

  # ===========================================================================
  # App <-> Noctalia theme wiring
  # ===========================================================================
  #
  # Noctalia generates the themes; these connect specific apps to them.

  # niri: config.kdl (in dotfiles/) has `include "noctalia.kdl"`; make sure
  # the file exists so niri doesn't error on a missing include before
  # Noctalia first renders it.
  home.activation.niriNoctaliaPlaceholder =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/niri"
      [ -e "$HOME/.config/niri/noctalia.kdl" ] || \
        $DRY_RUN_CMD touch "$HOME/.config/niri/noctalia.kdl"
    '';

  # ghostty
  programs.ghostty.settings.theme = "noctalia";

  # kate
  home.activation.kateNoctaliaTheme =
    lib.mkIf config.myApps.kate.enable
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/katerc" \
          --group "UiSettings" \
          --key "ColorScheme" \
          "noctalia"
      '');

  # qt6ct (only rewrites an existing conf; first run needs qt6ct launched once)
  home.activation.qt6ctNoctaliaTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      qt6ct_conf="$HOME/.config/qt6ct/qt6ct.conf"

      if [ -f "$qt6ct_conf" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed \
          -i \
          -e "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt6ct/colors/noctalia.conf|" \
          -e "s|^standard_dialogs=.*|standard_dialogs=xdgdesktopportal|" \
          "$qt6ct_conf"
      fi
    '';

  # ===========================================================================
  # Tiling-WM app behaviour
  # ===========================================================================

  # No CSD min/max/close buttons under a tiling compositor.
  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
    };
  };

  # Hide KDE System Settings from menus (not used on niri).
  xdg.dataFile."applications/systemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  xdg.dataFile."applications/kdesystemsettings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE System Settings
    NoDisplay=true
  '';

  # ===========================================================================
  # niri configuration (from dotfiles/)
  # ===========================================================================

  xdg.configFile = {
    "niri/animations.kdl".source                  = ../dotfiles/niri/animations.kdl;
    "niri/binds.kdl".source                       = ../dotfiles/niri/binds.kdl;
    "niri/config.kdl".source                      = ../dotfiles/niri/config.kdl;
    "niri/cursor.kdl".source                      = ../dotfiles/niri/cursor.kdl;
    "niri/decorations.kdl".source                 = ../dotfiles/niri/decorations.kdl;
    "niri/input.kdl".source                       = ../dotfiles/niri/input.kdl;
    "niri/layout.kdl".source                      = ../dotfiles/niri/layout.kdl;
    "niri/screenshots.kdl".source                 = ../dotfiles/niri/screenshots.kdl;
    "niri/spawn-at-startup.kdl".source            = ../dotfiles/niri/spawn-at-startup.kdl;
    "niri/window-rules.kdl".source                = ../dotfiles/niri/window-rules.kdl;
    "niri/output.kdl".source                      = ../hosts/${osConfig.networking.hostName}/niri/output.kdl;

    "noctalia/templates.toml".source              = ../dotfiles/noctalia/templates.toml;
    "noctalia/templates/oh-my-posh.json".source   = ../dotfiles/noctalia/templates/oh-my-posh.json;
  };
}
