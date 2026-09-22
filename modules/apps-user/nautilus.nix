# ../../modules/apps-user/nautilus.nix
#
# GNOME Files. Thumbnails (kdegraphics-thumbnailers/ffmpegthumbs, both
# freedesktop.org-spec and toolkit-agnostic) and network/NFS browsing
# (gvfs) are already provided unconditionally elsewhere - see
# home/common.nix and modules/services/gvfs.nix - so nothing else is
# needed here for feature parity with Dolphin.
{ config, pkgs, lib, ... }:

{
  options.myApps.nautilus.enable =
    lib.mkEnableOption "Nautilus (GNOME Files)";

  config = lib.mkIf config.myApps.nautilus.enable {
    home.packages = with pkgs; [
      nautilus
    ];
  };
}
