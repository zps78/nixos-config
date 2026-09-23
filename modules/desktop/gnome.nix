# ../../modules/desktop/gnome.nix
{ config, pkgs, lib, ... }:

lib.mkIf (config.myDesktop.stack == "gnome") {
  # X11/Wayland base
  services.xserver.enable = true;

  # Display manager
  services.displayManager.gdm = {
    enable = true;
  };

  # GNOME desktop
  services.desktopManager.gnome.enable = true;

  # dconf is required for GNOME settings
  programs.dconf.enable = true;

  # GNOME keyring
  services.gnome.gnome-keyring.enable = true;

  # Conflicts with programs.ssh.startAgent (modules/services/ssh.nix,
  # on for every host) - only one SSH agent can be installed at a time.
  # Same fix modules/desktop/niri.nix already applies.
  services.gnome.gcr-ssh-agent.enable = false;

  # Polkit authentication dialogs
  security.polkit.enable = true;

  # Portal integration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
    ];

    config = {
      common = {
        default = [ "gnome" "gtk" ];
      };
    };
  };

  # Useful GNOME additions
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
  ];

  # Makes system-package-shipped .thumbnailer files (glycin-thumbnailer,
  # gst-thumbnailers - both pulled in automatically by
  # services.desktopManager.gnome's own core-apps bundle) discoverable
  # via XDG_DATA_DIRS. Same reasoning as modules/desktop/niri.nix.
  environment.pathsToLink = [
    "share/thumbnailers"
  ];

  # RAW camera photo thumbnails/previews in Nautilus (and any other GTK
  # app) via a real gdk-pixbuf loader - GNOME's own glycin image-loading
  # stack doesn't cover RAW formats (checked: no libopenraw/libraw
  # anywhere in its build inputs or outputs), so this is still needed
  # even on GNOME's newer thumbnailing pipeline. Same mechanism as
  # modules/desktop/niri.nix - has to go through this NixOS module
  # option specifically, home-manager's home.packages doesn't trigger
  # regenerating GDK_PIXBUF_MODULE_FILE.
  programs.gdk-pixbuf.modulePackages = [ pkgs.libopenraw ];

  ############################################################
  # Wallpaper-derived theming (GNOME only - niri already has this via
  # Noctalia's own template engine, see dotfiles/noctalia/templates.toml
  # and home/niri.nix; running Stylix there too would just mean two
  # systems fighting over the same app configs)
  ############################################################
  #
  # stylix.base16Scheme deliberately left unset - Stylix then generates
  # a color scheme from stylix.image itself (a genetic-algorithm-based
  # extraction) rather than using a hand-picked palette. Unlike
  # Noctalia's live hook (pick a wallpaper in the GUI, theme
  # regenerates instantly, no rebuild), this is build-time/declarative:
  # changing the wallpaper here means changing this path and running
  # nixos-rebuild switch, not just picking a new background in GNOME
  # Settings.
  #
  # No target-by-target exclusions (e.g. GTK icon theme) - unlike
  # niri's Adwaita-Grey-Folders, which existed specifically to fix a
  # blue-folder visual clash in niri's own theming, not something GNOME
  # has, so there's nothing here for Stylix's icon target to fight.
  stylix.enable = true;
  stylix.polarity = "dark";
  stylix.image = ../../wallpapers/wallpaper-zp.jpg;
}
