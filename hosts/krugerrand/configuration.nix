# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Import modules
  imports = [
    ./hardware-configuration.nix
    ../../modules/core-apps.nix
    ../../modules/nfs-shares.nix
    ../../modules/nfs-torrents.nix
    ../../modules/hp-officejet-pro-8715.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "krugerrand";
  networking.nameservers = [ "100.100.100.100" "100.101.102.1" "9.9.9.9" "149.112.112.112" "8.8.8.8" "1.1.1.1" ];
  networking.search = [ "ojos-cloud.ts.net" ];

  # Tailscale
  services.tailscale.enable = true;

  # Fingerprint (ONLY for sudo)
  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;   # keep password login
    kde.fprintAuth = false;     # keep password for lock screen
    sddm.fprintAuth = false;    # keep password for graphical login
    sudo.fprintAuth = true;     # allow fingerprint for sudo (password still works)
  };

  # Graphics
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;  # ⭐ THIS is the key fix
    };
    open = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  hardware.graphics.enable = true;

  # Swap
  zramSwap = {
    enable = true;
    memoryPercent = 25; # ~16GB max on your 64GB system
  };
  swapDevices = [
    { device = "/swapfile"; size = 4096; }
  ];

  # Timezone & locales
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb.layout = "pt";
  console.keyMap = "pt-latin1";

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  security.rtkit.enable = true;

  # Libinput
  services.libinput.enable = true;
  services.libinput.touchpad.naturalScrolling = true;
  services.libinput.mouse.naturalScrolling = true;

  # Users
  users.users.zp = {
    isNormalUser = true;
    description = "zp";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Programs
  programs.firefox.enable = true;
  programs.kdeconnect.enable = true;
  programs.git.enable = true;
  programs.git.config.user.name = "zp";
  programs.git.config.user.email = "o.email.do.ze.pedro@gmail.com";

  # Unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
#    ragenix
#    tailscale
  ];

  # Printing
  services.printing.enable = true;

  # System state version
  system.stateVersion = "25.11";
}
