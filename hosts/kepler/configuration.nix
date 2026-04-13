# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix
    ../../modules/localization.nix
    ../../modules/kde.nix
#   ../../modules/hyprland.nix
    ../../modules/apps-core.nix
#    ../../modules/nfs-shares.nix
    ../../modules/nfs-torrents.nix
#   ../../modules/gpu-hybrid.nix
#   ../../modules/gpu-nvidia.nix
    ../../modules/gpu-amd.nix
    ../../modules/hp-officejet-pro-8715.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "kepler";
  networking.nameservers = [ "100.100.100.100" "100.101.102.1" "9.9.9.9" "149.112.112.112" "8.8.8.8" "1.1.1.1" ];
  networking.search = [ "ojos-cloud.ts.net" ];

  # Tailscale
  services.tailscale.enable = true;

  # Fingerprint (ONLY for sudo)
  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;   # keep password login
#    kde.fprintAuth = false;     # keep password for lock screen
    sddm.fprintAuth = false;    # keep password for graphical login
    sudo.fprintAuth = true;     # allow fingerprint for sudo (password still works)
  };

  # Swap
  zramSwap = {
    enable = true;
    memoryPercent = 25; # ~16GB max on your 64GB system
  };
  swapDevices = [
    { device = "/swapfile"; size = 4096; }
  ];

  # Desktop
  services.xserver.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  security.rtkit.enable = true;

  # Libinput - disabled because kde overrides it
#  services.libinput.enable = true;
#  services.libinput.touchpad.naturalScrolling = true;
#  services.libinput.mouse.naturalScrolling = true;

  # Users
  users.users.sc = {
    isNormalUser = true;
    description = "sc";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Programs
  programs.git.enable = true;
  programs.firefox.enable = true;
  programs.steam.enable = true;


  #  programs.git.config.user.name = "zp";
#  programs.git.config.user.email = "o.email.do.ze.pedro@gmail.com";

  # Unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    firefox
    git
    steam
    tailscale
  ];

  # System state version
  system.stateVersion = "25.11";
}
