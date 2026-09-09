# ../../modules/services/gvfs.nix
#
# Desktop integration for network/removable filesystems (SMB, SFTP, MTP,
# network browsing) - used by Dolphin, Nautilus, GNOME Files. Useful with
# the NAS.

{ ... }:

{
  services.gvfs.enable = true;
}
