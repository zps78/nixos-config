# ../../modules/apps-system/media-tools.nix
#
# Command-line media tools for conversions and remuxing on a headless host
# (kraken) - the CLI side of what the Unraid karma ran as containers
# (HandBrake NVENC, MKVToolNix, jMkvPropEdit). No GUIs: the desktop apps
# are per-user toggles (myApps.handbrake / myApps.mkvtoolnix).
#
#   HandBrakeCLI   with NVENC (nixpkgs builds it with nv-codec-headers)
#   mkvmerge / mkvpropedit / mkvextract / mkvinfo
#   mediainfo      stream details
#   dovi_tool, hdr10plus_tool   Dolby Vision / HDR10+ metadata
#   (ffmpeg-full is in the base set: modules/system/packages.nix)
#
# The user's HandBrake presets (exported from karma 2026-11-24, custom ones
# only) are at /etc/handbrake/presets.json:
#   HandBrakeCLI --preset-import-file /etc/handbrake/presets.json \
#     --preset 'Matroska/H.265 MKV 1080p x265 10bit CRF19 (Scene Style)' -i IN -o OUT
# Presets: "H.265 MKV 1080p NVEnc", "H.265 MKV 1080p x265 10bit CRF19
# (Scene Style)", "H.265 MKV 1080p30" (its fdk_aac audio isn't in nixpkgs'
# HandBrake build - HandBrake falls back to its own AAC encoder).
{ config, lib, pkgs, ... }:

let
  # HandBrake dlopens libnvidia-encode.so.1, which on NixOS lives in
  # /run/opengl-driver/lib - not on its search path. Without this it logs
  # "Cannot load libnvidia-encode.so.1" and the NVEnc preset silently falls
  # back to software x265 (tested 2026-11-24). A wrapper, not a rebuild.
  handbrake = pkgs.symlinkJoin {
    name = "handbrake-with-driver-libs";
    paths = [ pkgs.handbrake ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for b in HandBrakeCLI ghb; do
        [ -e $out/bin/$b ] && wrapProgram $out/bin/$b --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      done
    '';
  };
in
{
  options.myFeatures.media-tools.enable =
    lib.mkEnableOption "command-line media tools (HandBrakeCLI, MKVToolNix, mediainfo, HDR tools) + the HandBrake presets";

  config = lib.mkIf config.myFeatures.media-tools.enable {
    environment.systemPackages = with pkgs; [
      handbrake        # HandBrakeCLI, wrapped for NVENC (above); the package also carries the GUI
      mkvtoolnix-cli   # mkvmerge, mkvpropedit, mkvextract, mkvinfo
      mediainfo        # stream/container details
      dovi-tool        # Dolby Vision RPU extract/convert
      hdr10plus_tool   # HDR10+ metadata extract/inject
    ];

    environment.etc."handbrake/presets.json".source = ../../dotfiles/handbrake/presets.json;
  };
}
