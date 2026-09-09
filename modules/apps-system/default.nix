# ../../modules/apps-system/default.nix
#
# NixOS system-level app/capability modules. Imported per-host via
# ../../modules/apps-system, toggled with `myFeatures.*` in the host
# config. Use these for anything needing a NixOS-only option
# (programs.steam, firewall, hardware.*, system udev, ...).
{
  imports = [
    ./android.nix
    ./data-rescue.nix
    ./kde-connect.nix
    ./steam.nix
    ./wine.nix
  ];
}
