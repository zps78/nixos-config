# ../../modules/system/common.nix
{ pkgs, ... }:

{
  ############################################################
  # Run generic (non-Nix-built) Linux binaries
  ############################################################
  #
  # NixOS has no /lib64/ld-linux-x86-64.so.2 or FHS lib layout by
  # default, so prebuilt binaries that editors/tools fetch for
  # themselves (Zed's auto-installed language servers, VS Code's
  # remote-server bits, rustup, etc.) fail with "cannot run dynamically
  # linked executable". nix-ld provides that loader plus a small
  # library set. Extend `libraries` if a future error names a missing
  # .so nixpkgs doesn't cover here.
  #
  # Triggered by: Zed's "package-version-server" language server.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      icu
    ];
  };

  ############################################################
  # Nix core system behavior (ALL hosts)
  ############################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  ############################################################
  # Allow redistributable firmware (Wi-Fi, GPU, CPU microcode, etc.)
  ############################################################
  hardware.enableRedistributableFirmware = true;

  ############################################################
  # Base system utilities (safe everywhere)
  ############################################################
  programs.git.enable = true;
  services.fwupd.enable = true;
}
