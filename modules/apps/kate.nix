# ../../modules/apps/kate.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.kate.enable =
    lib.mkEnableOption "Kate";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.kate.enable {
    home.packages = with pkgs; [
      clang-tools
      kdePackages.kate
      marksman
      nil
    ];

  # ----------------------
  # KDL syntax highlighting
  # ----------------------
    xdg.dataFile."org.kde.syntax-highlighting/syntax/kdl.xml".source =
      pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/larsgw/katepart-kdl/main/kdl.xml";
        hash = "sha256-Hb0lChLsRstZQ02I1A/J7KWQ6OISMw7ji3zUNGWONu4=";
      };

  # ----------------------
  # KDL MIME type
  # ----------------------
    xdg.dataFile."mime/packages/kdl.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        <mime-type type="application/vnd.kdl">
          <comment>KDL document</comment>
          <glob pattern="*.kdl"/>
        </mime-type>
      </mime-info>
    '';

  # ----------------------
  # Default application
  # ----------------------
    xdg.mimeApps.defaultApplications = {
      "application/vnd.kdl" = "org.kde.kate.desktop";
    };
  };
}
