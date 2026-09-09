# ../../modules/hardware/audio.nix
{ ... }:

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

    wireplumber.enable = true;

    jack.enable = true;
  };

  # PipeWire's default quantum (floating 32-2048, 1024 default) is right
  # for general desktop use; a fixed low quantum only helps live audio
  # production and otherwise costs power and risks xruns.

  # Real-time scheduling
  security.rtkit.enable = true;
}
