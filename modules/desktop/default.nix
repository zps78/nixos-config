# ../../modules/desktop/default.nix
{ lib, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./kde.nix
    ./niri.nix
  ];

  options.myDesktop.stack = lib.mkOption {
    type = lib.types.enum [ "gnome" "kde" "niri" ];
    default = "niri";
    description = "Which desktop stack to enable for this host.";
  };

  options.myDesktop.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = ''
      The main login user on this host. Owns per-user runtime state that
      the system side needs to hand off (e.g. the greeter wallpaper cache).
    '';
  };

  options.myDesktop.idle.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether the shell locks / blanks / suspends on inactivity
      (Noctalia idle behaviors). Disable on hosts that must stay awake
      (e.g. game streaming, long renders).
    '';
  };
}
