# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix

    ../../modules/boot.nix
    ../../modules/memory.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix

    ../../modules/gpu-hybrid.nix
#   ../../modules/gpu-nvidia.nix
#   ../../modules/gpu-amd.nix

    ../../modules/localization.nix
    ../../modules/fonts.nix

    ../../modules/kde.nix
#   ../../modules/hyprland.nix

    ../../modules/nfs-shares.nix
    ../../modules/nfs-torrents.nix

    ../../modules/apps-core.nix
    ../../modules/tailscale.nix
    ../../modules/waydroid.nix

    ../../modules/hp-officejet-pro-8715.nix
  ];

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "krugerrand";

  # Fingerprint (ONLY for sudo)
  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;   # keep password login
#    kde.fprintAuth = false;     # keep password for lock screen
    sddm.fprintAuth = false;    # keep password for graphical login
    sudo.fprintAuth = true;     # allow fingerprint for sudo (password still works)
  };

  # Memory
  boot.kernel.sysctl."vm.swappiness" = 60;

  # Libinput - disabled because kde overrides it
#  services.libinput.enable = true;
#  services.libinput.touchpad.naturalScrolling = true;
#  services.libinput.mouse.naturalScrolling = true;

  # Users
  users.users.zp = {
    isNormalUser = true;
    description = "zp";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Programs
#  programs.firefox.enable = true; # in user.nix file
#  programs.steam.enable = true;
  programs.git.enable = true;
  programs.git.config.user.name = "zp";
  programs.git.config.user.email = "o.email.do.ze.pedro@gmail.com";

  # Unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
#    tailscale
  ];

  # System state version
  system.stateVersion = "25.11";
}
