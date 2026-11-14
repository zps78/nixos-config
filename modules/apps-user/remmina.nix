# ../../modules/apps-user/remmina.nix
{ config, pkgs, lib, ... }:

let
  # shared-mime-info has no type for Microsoft .rdp connection files, so
  # they're detected as text/plain and open in a text editor. Register one.
  rdpMimeType = pkgs.writeTextDir "share/mime/packages/rdp.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-rdp">
        <comment>Remote Desktop connection</comment>
        <glob pattern="*.rdp"/>
      </mime-type>
    </mime-info>
  '';
in
{
  options.myApps.remmina.enable = lib.mkEnableOption "Remmina";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.remmina.enable {
    home.packages = with pkgs; [
      remmina
      rdpMimeType     # picked up by home-manager's xdg.mime database build
    ];

    # Remmina's own desktop files only claim rdp:// links and .remmina
    # files, not .rdp. `remmina -c <file>` imports an .rdp and connects,
    # so give it a (menu-hidden) entry that handles the new type and make
    # it the default.
    xdg.desktopEntries.remmina-rdp = {
      name = "Remmina (RDP file)";
      exec = "remmina -c %f";
      icon = "org.remmina.Remmina";
      mimeType = [ "application/x-rdp" ];
      noDisplay = true;
    };

    xdg.mimeApps.defaultApplications."application/x-rdp" = "remmina-rdp.desktop";
  };
}
