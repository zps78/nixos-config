# ../../modules/apps-user/bottles.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.bottles.enable =
    lib.mkEnableOption "Bottles";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.bottles.enable {
    home.packages = [
      # Upstream Bottles added a "not sandboxed"/"unsupported environment"
      # popup specifically targeting non-Flatpak distro packaging (they no
      # longer want to support third-party builds). nixpkgs kept the check
      # non-fatal but left the popup on by default; removeWarningPopup
      # swaps in nixpkgs' own patch that drops it entirely.
      (pkgs.bottles.override { removeWarningPopup = true; })
    ];
  };
}
