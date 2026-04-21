# ../../modules/boot.nix
{ config, pkgs, lib, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Boot experience
  boot.plymouth.enable = true;

  # Use systemd in initrd (modern + faster boot)
  boot.initrd.systemd.enable = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
