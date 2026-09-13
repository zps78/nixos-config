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

    # Proton bundles a native accessibility bridge ("Xalia") that's meant
    # to auto-disable itself when it detects a Wayland session (Proton's
    # own source: "It is not possible for winewayland to support xalia").
    # That detection doesn't work reliably from inside umu/pressure-
    # vessel's nested containers, so Xalia tries to SDL_Init a display,
    # finds none reachable in the sandbox, and crashes with "No displays
    # available" - fatally, since this happens BEFORE wine itself starts.
    # Only hit on fresh prefix creation (an existing prefix skips this
    # bootstrap step), which is why a first install/reinstall fails while
    # an already-installed UMU game keeps launching fine. Confirmed via
    # direct reproduction: identical install hung/crashed every time
    # without this, succeeded (full prefix populated) every time with it.
    home.sessionVariables.PROTON_USE_XALIA = "0";
  };
}
