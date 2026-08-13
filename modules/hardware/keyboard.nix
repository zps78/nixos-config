# ../../modules/hardware/keyboard.nix
{ config, lib, ... }:

{
  options.myHardware.keyboard = {
    layout = lib.mkOption {
      type = lib.types.enum [ "pt" "gb" "us" ];
      default = "pt";
      description = "Primary keyboard layout.";
    };

    secondLayout = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "pt" "gb" "us" ]);
      default = null;
      description = "Optional second keyboard layout.";
    };
  };

  config = {

    # X11 / Wayland keyboard
    services.xserver.xkb = {
      layout =
        if config.myHardware.keyboard.secondLayout == null
        then config.myHardware.keyboard.layout
        else
          "${config.myHardware.keyboard.layout},${config.myHardware.keyboard.secondLayout}";

      options = lib.mkIf (config.myHardware.keyboard.secondLayout != null)
        "grp:alt_space_toggle";
    };

    # Console (TTY)
    console.keyMap =
      if config.myHardware.keyboard.layout == "pt" then "pt-latin1"
      else if config.myHardware.keyboard.layout == "gb" then "uk"
      else "us";
  };
}
