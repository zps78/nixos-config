# ../../modules/apps/sc.nix
{ config, pkgs, ... }:

{
  # Import modules
  imports = [
    ../../modules/apps/firefox.nix
    ../../modules/apps/plex.nix
  ];

    programs.vscodium = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      enkia.tokyo-night
      esbenp.prettier-vscode
      jeff-hykin.better-nix-syntax
    ];
  };

  # ----------------------
  # Packages
  # ----------------------
  home.packages = with pkgs; [
   ## Development
      godot
      vscode
    # vscodium

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
    # remmina
    # teamviewer

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
