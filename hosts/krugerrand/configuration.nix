# ../../hosts/krugerrand/configuration.nix
{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/gpu-hybrid.nix
#   ../../modules/hardware/gpu-nvidia.nix
#   ../../modules/hardware/gpu-amd.nix

    ../../modules/system/boot.nix
    ../../modules/system/common.nix
    ../../modules/system/localization.nix
    ../../modules/system/memory.nix

    ../../modules/desktop/fonts.nix
#   ../../modules/desktop/hyprland.nix
    ../../modules/desktop/kde.nix

    ../../modules/networking/nfs-shares.nix
    ../../modules/networking/nfs-torrents.nix
    ../../modules/networking/tailscale.nix

    ../../modules/apps/core.nix

    ../../modules/services/hp-officejet-pro-8715.nix
    ../../modules/services/waydroid.nix
  ];

  # Memory
  boot.kernel.sysctl."vm.swappiness" = 60;

  # Networking
  networking.hostName = "krugerrand";

  # Users
  users.users.zp = {
    isNormalUser = true;
    description = "zp";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Fingerprint (ONLY for sudo)
  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;   # keep password login
#    kde.fprintAuth = false;     # keep password for lock screen
    sddm.fprintAuth = false;    # keep password for graphical login
    sudo.fprintAuth = true;     # allow fingerprint for sudo (password still works)
  };


  # Libinput - disabled because kde overrides it
#  services.libinput.enable = true;
#  services.libinput.touchpad.naturalScrolling = true;
#  services.libinput.mouse.naturalScrolling = true;

  # Programs
#  programs.firefox.enable = true; # in user.nix file
#  programs.steam.enable = true;
  programs.git.config.user.name = "zp";
  programs.git.config.user.email = "o.email.do.ze.pedro@gmail.com";


  # System packages
  environment.systemPackages = with pkgs; [
#    tailscale
  ];

  # System state version
  system.stateVersion = "25.11";
}
