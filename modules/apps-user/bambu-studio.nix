# ../../modules/apps-user/bambu-studio.nix
{ config, pkgs, lib, osConfig, ... }:

let
  gpu = osConfig.myHardware.gpuVendor;
  # nixpkgs' withNvidiaGLWorkaround forces mesa/zink GL - needed on
  # nvidia / hybrid hosts to avoid GLEW/GL crashes in the app.
  bambu-studio = pkgs.bambu-studio.override {
    withNvidiaGLWorkaround = gpu == "nvidia" || gpu == "hybrid";
  };
in
{
  options.myApps.bambu-studio.enable =
    lib.mkEnableOption "Bambu-studio";

  config = lib.mkIf config.myApps.bambu-studio.enable {
    home.packages = [ bambu-studio ];

    # "Open with Bambu Studio" in Nautilus' right-click menu for the model
    # types F3D is the default viewer for (home/mime.nix), so F3D stays
    # the double-click app. Only offered for types Bambu Studio's own
    # .desktop file also claims, so it never shows for a file it can't
    # open. Same nautilus-python setup as myApps.pdfarranger's menu item.
    xdg.dataFile."nautilus-python/extensions/bambu-studio-open-with.py".text = ''
      import gi
      gi.require_version("Nautilus", "4.1")
      from gi.repository import GObject, Nautilus

      try:
          gi.require_version("GioUnix", "2.0")
          from gi.repository.GioUnix import DesktopAppInfo
      except (ValueError, ImportError):
          from gi.repository.Gio import DesktopAppInfo

      APP_ID = "BambuStudio.desktop"
      # F3D's types in home/mime.nix
      F3D_TYPES = {
          "model/3mf", "application/vnd.ms-3mfdocument",
          "model/stl",
          "model/step", "application/vnd.step",
      }


      def _supported():
          app = DesktopAppInfo.new(APP_ID)
          if app is None:
              return set()
          return F3D_TYPES & set(app.get_supported_types() or [])


      class BambuStudioOpenWith(GObject.GObject, Nautilus.MenuProvider):
          def get_file_items(self, files):
              types = _supported()
              if not files or any(f.get_mime_type() not in types for f in files):
                  return []
              item = Nautilus.MenuItem(
                  name="BambuStudioOpenWith::Open",
                  label="Open with Bambu Studio",
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
