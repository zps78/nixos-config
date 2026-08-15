# ../../modules/hardware/keyboard.nix
#{ config, lib, ... }:

#{
#  options.myHardware.keyboard = {
#    layout = lib.mkOption {
#      type = lib.types.enum [ "pt" "gb" "us" ];
#      default = "pt";
#      description = "Primary keyboard layout.";
#    };

#    secondary.layout = lib.mkOption {
#      type = lib.types.nullOr (lib.types.enum [ "pt" "gb" "us" ]);
#      default = null;
#      description = "Optional second keyboard layout.";
#    };
#  };

#  config = {

#    # X11 / Wayland keyboard
#    services.xserver.xkb = {
#      layout =
#        if config.myHardware.keyboard.secondary.layout == null
#        then config.myHardware.keyboard.layout
#        else
#          "${config.myHardware.keyboard.layout},${config.myHardware.keyboard.secondary.layout}";


#      # Always provide Alt+Space as a layout toggle when a
#      # secondary layout is configured.
#      options = lib.mkIf
#        (config.myHardware.keyboard.secondary.layout != null)
#        "grp:alt_space_toggle";
#    };

    # TTY keyboard layout follows the primary layout.
#    console.keyMap =
#      if config.myHardware.keyboard.layout == "pt" then "pt-latin1"
#      else if config.myHardware.keyboard.layout == "gb" then "uk"
#      else "us";
#  };
#}



# ../../modules/hardware/keyboard.nix
{ config, lib, pkgs, ... }:

let
  primaryLayout = config.myHardware.keyboard.layout;

  copilotLayout = "copilot-${primaryLayout}";

copilotSymbols = pkgs.writeText copilotLayout ''
  partial alphanumeric_keys
  xkb_symbols "${copilotLayout}" {
    include "${primaryLayout}(basic)"

    key <FK23> {
      type = "PC_SUPER_LEVEL2",
      symbols[Group1] = [ F23, ISO_Next_Group ]
    };
  };
'';
in
{
  options.myHardware.keyboard = {
    layout = lib.mkOption {
      type = lib.types.enum [ "pt" "gb" "us" ];
      default = "pt";
      description = "Primary keyboard layout.";
    };

    secondary.layout = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "pt" "gb" "us" ]);
      default = null;
      description = "Optional second keyboard layout.";
    };
  };

  config = {
    services.xserver.xkb = {
      layout =
        if config.myHardware.keyboard.secondary.layout == null
        then primaryLayout
        else "${copilotLayout},${config.myHardware.keyboard.secondary.layout}";

      options = lib.mkIf
        (config.myHardware.keyboard.secondary.layout != null)
        "grp:alt_space_toggle";

      extraLayouts.${copilotLayout} = {
        description = "Custom ${primaryLayout} layout with Copilot group toggle";
        languages = [ "eng" "por" ];
        symbolsFile = copilotSymbols;
      };
    };

    console.keyMap =
      if primaryLayout == "pt" then "pt-latin1"
      else if primaryLayout == "gb" then "uk"
      else "us";
  };
}
