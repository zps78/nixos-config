# ../../modules/apps-user/orca-slicer.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.orca-slicer.enable =
    lib.mkEnableOption "Orca-slicer";

  config = lib.mkIf config.myApps.orca-slicer.enable {
    home.packages = with pkgs; [
      orca-slicer
    ];

    # Selecting a Bambu (P1S) profile makes OrcaSlicer download a
    # proprietary network plugin into ~/.config/OrcaSlicer/plugins/. That
    # blob is linked against a different libstdc++ and crashes the app
    # (free(): invalid size) on NixOS - nixpkgs maintains the plugin
    # workarounds for bambu-studio, not orca-slicer. Pin the dir read-only
    # so the download can't land; use Bambu Studio for device/cloud.
    home.file.".config/OrcaSlicer/plugins".source = pkgs.emptyDirectory;
  };
}
