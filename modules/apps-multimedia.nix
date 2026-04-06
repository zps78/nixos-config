{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Multimedia
    audacity
    bambu-studio
#    clipgrab
    darktable
    ffmpeg-full
    gimp
    handbrake
    losslesscut-bin
    mkvtoolnix
    plex-desktop
    spotify
    vlc
  ];
}
