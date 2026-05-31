{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.alacritty.enable = true;
  programs.swaylock.enable = true;
  services.mako.enable = true;

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "niri msg action power-off-monitors"; }
    ];
  };

  programs.noctalia-shell = {
    enable = true;
    settings = { };
  };

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard { xkb { layout "pt"; } }
        touchpad { tap; natural-scroll; accel-speed 0.2; }
    }
    layout { gaps 8; }
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "mako"
    spawn-at-startup "swaybg" "-m" "fill" "-i" "/home/zp/Pictures/wallpaper.jpg"
    spawn-at-startup "noctalia-shell"
    binds {
        Mod+T { spawn "alacritty"; }
        Mod+Q { close-window; }
        Mod+Alt+L { spawn "swaylock" "-f"; }
        Mod+D { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
        XF86MonBrightnessUp   { spawn "noctalia-shell" "ipc" "call" "brightness" "increase"; }
        XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
        XF86AudioRaiseVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute         { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioPlay         { spawn "playerctl" "play-pause"; }
    }
  '';
}