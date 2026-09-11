# ../../modules/apps-user/default.nix
#
# Home Manager app modules. Imported per-user via ../../modules/apps-user
# (from home/users/*.nix), toggled with `myApps.*`. Use these for user
# programs: home.packages or HM programs.* options.
{
  imports = [
    ./ardour.nix
    ./audacity.nix
    ./bambu-studio.nix
    ./blender.nix
    ./bottles.nix
    ./brave.nix
    ./cava.nix
    ./chiaki-ng.nix
    ./darktable.nix
    ./easyeffects.nix
    ./f3d.nix
    ./firefox.nix
    ./freecad.nix
    ./freetube.nix
    ./gimp.nix
    ./godot.nix
    ./handbrake.nix
    ./iptvnator.nix
    ./kdl.nix
    ./krita.nix
    ./losslesscut.nix
    ./lutris.nix
    ./mkvtoolnix.nix
    ./moonlight.nix
    ./mpv.nix
    ./obs-studio.nix
    ./office.nix
    ./openscad.nix
    ./orca-slicer.nix
    ./plex.nix
    ./plex-tui.nix
    ./proton-pass.nix
    ./spotatui.nix
    ./spotify.nix
    ./steam-extras.nix
    ./telegram.nix
    ./thunderbird.nix
    ./vlc.nix
    ./vscodium.nix
    ./zed.nix
    ./zen-browser.nix
  ];
}
