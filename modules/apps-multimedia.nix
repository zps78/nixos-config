{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Multimedia
    audacity
#    clipgrab
    ffmpeg-full
    handbrake
    losslesscut-bin
    mkvtoolnix
    plex-desktop
    spotify
    vlc
  ];
}
