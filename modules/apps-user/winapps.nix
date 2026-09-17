# ../../modules/apps-user/winapps.nix
{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.myApps.winapps;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.myApps.winapps.enable =
    lib.mkEnableOption "WinApps";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.winapps.packages.${system}.winapps            # winapps, winapps-setup
      inputs.winapps.packages.${system}.winapps-launcher    # GUI launcher (needs yad)
    ];

    # ~/.config/winapps/winapps.conf is intentionally NOT declared here -
    # it holds the Windows RDP password in plaintext, same call as
    # sunshine.conf (modules/services/sunshine.nix): runtime credentials
    # stay out of the git-tracked nix store. Created by hand once on each
    # machine that runs WinApps - see winapps-org/winapps docs for the
    # RDP_USER/RDP_PASS/RDP_IP/WAFLAVOR=manual format. Pointed at karma's
    # "Office" libvirt VM (WAFLAVOR=manual, no local Docker/libvirt VM
    # managed by WinApps itself).
  };
}
