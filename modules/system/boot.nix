# ../../modules/system/boot.nix
{ config, pkgs, lib, ... }:

{
  # ----------------------------
  # Bootloader (system entry)
  # ----------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 7;
  boot.loader.systemd-boot.editor = false;

  # ----------------------------
  # Faster boot (avoid network wait delays)
  # ----------------------------
  systemd.services.NetworkManager-wait-online.enable = false;

  # ----------------------------
  # Boot experience (UI)
  # ----------------------------
  boot.plymouth.enable = true;

  # ----------------------------
  # Init system (modern boot chain)
  # ----------------------------
  boot.initrd.systemd.enable = true;

  # ----------------------------
  # Kernel selection
  # ----------------------------
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
