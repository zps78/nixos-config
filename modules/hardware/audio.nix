# ../../modules/hardware/audio.nix
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

    wireplumber.enable = true;

    jack.enable = true;
  };

  # Optional but recommended for low latency
  services.pipewire.extraConfig.pipewire = {
    "99-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 128;
        default.clock.min-quantum = 128;
        default.clock.max-quantum = 128;
      };
    };
  };

  # Real-time scheduling (important for low-latency audio)
  security.rtkit.enable = true;
}
