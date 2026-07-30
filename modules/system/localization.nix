# ../../modules/system/localization.nix
{ config, lib, pkgs, ... }:

{
  options.myHardware.keyboard.layout = lib.mkOption {
    type = lib.types.enum [ "pt" "gb" "us" ];
    default = "pt";
    description = "Keyboard layout for X11/Wayland and console.";
  };

  config = {
    # Timezone
    time.timeZone = "Europe/Lisbon";

    # X11 / Wayland keyboard
    services.xserver.xkb.layout = config.myHardware.keyboard.layout;

    # Console (TTY)
    console.keyMap =
      if config.myHardware.keyboard.layout == "pt" then "pt-latin1"
      else if config.myHardware.keyboard.layout == "gb" then "uk"
      else "us";

  # Locale
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_IE.UTF-8";
      LC_IDENTIFICATION = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETARY = "en_IE.UTF-8";
      LC_NAME = "en_IE.UTF-8";
      LC_NUMERIC = "en_IE.UTF-8";
      LC_PAPER = "en_IE.UTF-8";
      LC_TELEPHONE = "en_IE.UTF-8";
      LC_TIME = "en_IE.UTF-8";
    };
  };
}
