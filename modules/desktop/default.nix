# ../../modules/desktop/default.nix
{ config, lib, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./kde.nix
    ./niri.nix
    ./steam-gamescope.nix
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

  options.myDesktop.sessionUser = lib.mkOption {
    type = lib.types.str;
    default = config.myDesktop.primaryUser;
    defaultText = lib.literalExpression "config.myDesktop.primaryUser";
    description = ''
      The user whose graphical session runs on this host's screen (the
      autologin / Sunshine user). Defaults to primaryUser. Set it apart
      when the desktop should belong to an unprivileged account - e.g.
      krieger's "steam" user, while primaryUser stays the admin account
      that gets SSH keys, docker, libvirt and remote-builder access.
      Owns the session-side state: the greeter wallpaper hand-off and
      Sunshine's virtual input devices.
    '';
  };

  options.myDesktop.idle.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether the shell locks / blanks / suspends on inactivity
      (Noctalia idle behaviors). Disable on hosts that must stay awake
      (e.g. game streaming, long renders).

      When enabled, idle is additionally inhibited automatically while
      more than one output is connected (docked / external displays).
    '';
  };
}
