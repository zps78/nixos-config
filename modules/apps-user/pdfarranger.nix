# ../../modules/apps-user/pdfarranger.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.pdfarranger.enable =
    # on for every user unless a user file turns it off
    lib.mkEnableOption "PDF Arranger" // { default = true; };

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.pdfarranger.enable {
    home.packages = with pkgs; [
      pdfarranger # Merge or split pdf documents and rotate, crop and rearrange their pages using a graphical interface
    ];

    # "Open with PDF Arranger" in Nautilus' right-click menu for PDFs, so
    # Papers can stay the default. Nautilus only lists the default app
    # there; this adds the item through nautilus-python (installed and
    # wired up in modules/desktop/{niri,gnome}.nix). Several selected
    # PDFs open together in one PDF Arranger window.
    xdg.dataFile."nautilus-python/extensions/pdfarranger-open-with.py".text = ''
      import gi
      gi.require_version("Nautilus", "4.1")
      from gi.repository import GObject, Nautilus

      try:
          gi.require_version("GioUnix", "2.0")
          from gi.repository.GioUnix import DesktopAppInfo
      except (ValueError, ImportError):
          from gi.repository.Gio import DesktopAppInfo

      APP_ID = "com.github.jeromerobert.pdfarranger.desktop"


      class PdfArrangerOpenWith(GObject.GObject, Nautilus.MenuProvider):
          def get_file_items(self, files):
              if not files or any(f.get_mime_type() != "application/pdf" for f in files):
                  return []
              item = Nautilus.MenuItem(
                  name="PdfArrangerOpenWith::Open",
                  label="Open with PDF Arranger",
              )
              item.connect("activate", self._open, files)
              return [item]

          def _open(self, _item, files):
              app = DesktopAppInfo.new(APP_ID)
              if app is not None:
                  app.launch([f.get_location() for f in files], None)
    '';
  };
}
