# ../../modules/apps/zp.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
    ../../modules/apps/plex.nix
  ];
  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
    # godot
    # vscode
      vscodium

   ## Media
    # obs-studio
      spotify
    # sunshine        # -> import sunshine.nix in the host's configuration.nix

   ## Internet
    # brave
    # filezilla
    # thunderbird     # -> enabled in core.nix

   ## Gaming
    # steam           # -> import steam.nix in the host's configuration.nix

   ## Remote access
      moonlight-qt
      remmina
      teamviewer

   ## Wine
    # wine            # -> import wine.nix in the host's configuration.nix

   ## Virtualization / Emulation
    # libvirt         # -> import libvirt.nix in the host's configuration.nix
    # waydroid        # -> import waydroid.nix in the host's configuration.nix

   ## Office
      onlyoffice-desktopeditors
      xournalpp
  ];
}
