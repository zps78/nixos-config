# ../../modules/apps-user/losslesscut.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.losslesscut.enable =
    lib.mkEnableOption "LosslessCut";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.losslesscut.enable {
    home.packages = with pkgs; [
      losslesscut-bin
    ];

    # The upstream (AppImage) .desktop has no MimeType=, so LosslessCut
    # never shows under "Open With" for video/audio files. Same entry plus
    # the types mpv handles (home/mime.nix) - mpv stays the default.
    # ~/.local/share/applications shadows the profile's copy (and a second
    # entry in the profile would collide with the package's).
    xdg.dataFile."applications/losslesscut.desktop".text = ''
      [Desktop Entry]
      Name=LosslessCut
      Exec=losslesscut --no-sandbox %U
      Terminal=false
      Type=Application
      Icon=losslesscut
      StartupWMClass=LosslessCut
      Comment=The swiss army knife of lossless video/audio editing
      Categories=AudioVideo;
      MimeType=video/mp4;video/x-matroska;video/mkv;video/webm;video/mpeg;video/avi;video/x-avi;video/x-msvideo;video/quicktime;video/x-flv;video/x-ms-wmv;video/ogg;video/3gp;video/mp2t;audio/mpeg;audio/mp4;audio/m4a;audio/flac;audio/ogg;audio/wav;audio/x-wav;audio/aac;audio/opus;audio/ac3;audio/eac3;audio/webm;
    '';
  };
}
