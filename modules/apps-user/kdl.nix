# ../../modules/apps-user/kdl.nix
#
# KDL (.kdl) MIME-type registration. Desktop/editor-agnostic and always
# on: .kdl files (niri config, etc.) need to be recognised as
# application/vnd.kdl so anything can claim a default handler for them.
#
# Editor-side pieces live elsewhere:
#   - Kate katepart syntax highlighting -> kate.nix (gated on myApps.kate)
#   - Zed "kdl" extension               -> zed.nix  (gated on myApps.zed)
#   - default application for .kdl       -> home/mime.nix
{ pkgs, lib, ... }:

{
  xdg.dataFile."mime/packages/kdl.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/vnd.kdl">
        <comment>KDL document</comment>
        <glob pattern="*.kdl"/>
      </mime-type>
    </mime-info>
  '';

  home.activation.updateKdlMimeDatabase =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.shared-mime-info}/bin/update-mime-database \
        "$HOME/.local/share/mime"
    '';
}
