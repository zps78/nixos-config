# ../../modules/system/common.nix
{ ... }:

{
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
