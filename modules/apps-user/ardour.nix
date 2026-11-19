# ../../modules/apps-user/ardour.nix
#
# Ardour talks to PipeWire through its JACK backend. Instead of the
# system-wide services.pipewire.jack.enable (deprecated: it swaps
# PipeWire's libjack in for every program via LD_LIBRARY_PATH), only
# Ardour's own binaries get PipeWire's libjack - what `pw-jack ardour9`
# does, baked into the package so the desktop entry works as-is.
{ config, pkgs, lib, ... }:

let
  ardour = pkgs.symlinkJoin {
    name = "ardour-pw-jack-${pkgs.ardour.version}";
    paths = [ pkgs.ardour ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for f in $out/bin/*; do
        wrapProgram "$f" --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      done
    '';
  };
in
{
  options.myApps.ardour.enable =
    lib.mkEnableOption "Ardour";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.ardour.enable {
    home.packages = [
      ardour
    ];
  };
}
