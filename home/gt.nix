# ../../home/gt.nix
{ config, pkgs, inputs, ... }:

{
  ############################################################
  # Home Manager basics
  ############################################################

  home.username = "gt";
  home.homeDirectory = "/home/gt";
  home.stateVersion = "25.11"; # match your NixOS version

  ############################################################
  # Imports (user environment composition)
  ############################################################

  imports = [
  # ./niri.nix
    ../modules/apps/3d.nix
    ../modules/apps/firefox.nix
    ../modules/apps/godot.nix
    ../modules/apps/plex.nix
    ../modules/apps/vscodium.nix
    ../modules/apps/zen-browser.nix
  ];

  ############################################################
  # User applications (only truly global desktop apps)
  ############################################################

  myApps.godot.enable = false;

  myApps.vscodium.enable = true;

  programs.thunderbird.enable = false;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "gt";
        email = "mostly@kimi";
      };
      init.defaultBranch = "main";
    };
  };

  home.packages = with pkgs; [
 ## Media
  # obs-studio
  # spotify

 ## Remote access
  # moonlight-qt
    remmina
  # sunshine        # -> import sunshine.nix in the host's configuration.nix
  # teamviewer

 ## Office
  # onlyoffice-desktopeditors
  # xournalpp

 ## Gaming
  # steam           # -> import steam.nix in the host's configuration.nix

 ## Virtualization / Emulation
  # libvirt         # -> import libvirt.nix in the host's configuration.nix
  # waydroid        # -> import waydroid.nix in the host's configuration.nix
  # wine            # -> import wine.nix in the host's configuration.nix
  ];

  # ----------------------
  # Optional: autostart scripts or custom config can go here
  # ----------------------

}
