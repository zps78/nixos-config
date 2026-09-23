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
}
