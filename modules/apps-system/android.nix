# ../../modules/apps-system/android.nix
#
# Android tooling (system level: udev, CLI tools).
#
# Provides:
# - ADB / Fastboot (android-tools)
# - scrcpy (screen mirroring)
# - APK inspection (apktool, apkeep)
#
# adb over network: `adb tcpip 5555` then `adb connect <ip>:5555`
# (scrcpy: `scrcpy --tcpip=<ip>`).

{ config, lib, pkgs, ... }:

{
  options.myFeatures.android.enable =
    lib.mkEnableOption "Android tooling (ADB, scrcpy, APK tools)";

  config = lib.mkIf config.myFeatures.android.enable {
    environment.systemPackages = with pkgs; [
      android-tools  # ADB / fastboot
      scrcpy         # screen mirroring / control
      apktool        # APK decompile/rebuild
      apkeep         # download APKs from various sources
    ];
  };
}
