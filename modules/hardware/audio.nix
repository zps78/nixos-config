# ../../modules/audio.nix
{ config, pkgs, lib, ... }:

{
  # Disable legacy PulseAudio
  services.pulseaudio.enable = false;

  # Enable PipeWire (modern audio stack)
  services.pipewire = {
    enable = true;

    alsa = {
      enable = true;
      support32Bit = true; # needed for Steam/Wine
    };

    pulse.enable = true; # PulseAudio compatibility layer
  };

  # Real-time scheduling (important for low-latency audio)
  security.rtkit.enable = true;
}
