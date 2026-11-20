# ../../hosts/kraken/hardware-configuration.nix
#
# Hand-written, NOT from nixos-generate-config: the disk layout is fixed
# in advance by hosts/kraken/INSTALL.md, so nothing here depends on
# UUIDs that only exist after partitioning. After the install, diff this
# against `nixos-generate-config --show-hardware-config` and take any
# extra kernel modules it finds.
#
# Board: ASUS ROG Crosshair VIII Formula (X570), Ryzen 9 5950X - krieger's
# old internals, moving into the Jonsbo N5.
#
# OS disk: Samsung 990 Pro 1TB in M.2_1 (CPU lanes)
#   p1  "kraken-esp"  1 GiB  vfat  -> /boot
#   p2  "kraken-zfs"  rest   ZFS pool "rpool"
#
# rpool datasets (all mountpoint=legacy, mounted below):
#   rpool/local/*  rebuildable - never snapshotted or backed up
#   rpool/safe/*   real state - snapshotted (sanoid) and replicated
{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
  };

  # Docker's image/container layers: rebuildable, so not under safe/.
  fileSystems."/var/lib/docker" = {
    device = "rpool/local/docker";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = "rpool/safe/var";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
  };

  # Container/service config and databases (karma's old nvme-appdata pool).
  fileSystems."/srv/appdata" = {
    device = "rpool/safe/appdata";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/kraken-esp";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
