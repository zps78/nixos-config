# ../../modules/apps-system/proxmark3.nix
#
# Proxmark3 RFID/NFC tooling (system level: udev, CLI client).
#
# pkgs.proxmark3 builds from RfidResearchGroup/proxmark3 - the "Iceman"
# fork/firmware, not the older official proxmark3 client - so this is
# already the right package, no custom build needed.
#
# The package ships its own udev rule (tells ModemManager to ignore the
# device instead of probing it as a modem, and sets the serial device to
# GROUP="dialout", MODE="660"). services.udev.packages is what actually
# installs that rule; environment.systemPackages alone does not.
#
# Also adds every normal user on the host to "dialout" (the group the
# udev rule above grants device access to), so whoever's logged in can
# use it without a per-host extraGroups edit. This is done via
# users.groups.dialout.members (not users.users.<name>.extraGroups) -
# writing extraGroups back onto users.users while also reading it to
# find normal users is a self-reference and triggers infinite recursion.
#
# Usage once plugged in: `pm3` to connect, `pm3-flash-all` to flash
# firmware/bootrom/fpga images in one go.

{ config, lib, pkgs, ... }:

{
  options.myFeatures.proxmark3.enable =
    lib.mkEnableOption "Proxmark3 RFID/NFC tooling (Iceman client, udev rule)";

  config = lib.mkIf config.myFeatures.proxmark3.enable {
    environment.systemPackages = [ pkgs.proxmark3 ];
    services.udev.packages = [ pkgs.proxmark3 ];

    users.groups.dialout.members =
      lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
  };
}
