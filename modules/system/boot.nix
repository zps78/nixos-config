{ config, pkgs, lib, ... }:

{
  # ----------------------------
  # Bootloader (system entry)
  # ----------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ----------------------------
  # Faster boot (avoid network wait delays)
  # ----------------------------
  systemd.network.wait-online.enable = lib.mkDefault false;
  boot.initrd.systemd.network.wait-online.enable = false;
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
