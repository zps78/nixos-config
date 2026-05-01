# ../../modules/apps/android.nix
#
# Android tooling module for NixOS
#
# Provides:
# - ADB / Fastboot
# - scrcpy (screen mirroring)
# - udev rules for device access
# - optional wireless debugging support
#
# Works for:
# - Pixel / Samsung / general Android devices
# - USB + wireless ADB
#

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Android CLI tools
    android-tools

    # Screen mirroring / control
    scrcpy

    # Useful for debugging APKs and devices
    apktool

    # Command-line tool for downloading APK files from various sources
    apkeep
  ];

  # -------------------------------------------------
  # Optional convenience: adb over network
  # -------------------------------------------------
  # Nothing to enable system-wide; usage is:
  #   adb tcpip 5555
  #   adb connect <device-ip>:5555
  #
  # scrcpy supports:
  #   scrcpy --tcpip=<ip>
  #
}
