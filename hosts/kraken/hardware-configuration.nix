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

  # Podman's images/containers (StemDeck): rebuildable, so not under safe/.
  # Created with `zfs create -o mountpoint=legacy rpool/local/containers`.
  # (Replaced Docker and its rpool/local/docker on 2026-11-26.)
  fileSystems."/var/lib/containers" = {
    device = "rpool/local/containers";
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

  # Steam library: pool "games" on the WD Red SA500 1TB (serial
  # 233902800851, ex karma ssd-home), created 2026-11-21. Single disk,
  # lz4, atime off, NOT snapshotted (games re-download). nofail: kraken
  # boots without it. Owned by the steam user.
  fileSystems."/mnt/games" = {
    device = "games/steam";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-games.service" "x-systemd.after=zfs-import-games.service" ];
  };

  # Game saves backup (myStorage.gameSaves): dataset vault/gamesaves on the
  # 4x 4TB mirrors (the job snapshots it after each backup). Created 2026-11-24 with
  # `zfs create -o mountpoint=legacy vault/gamesaves`. nofail like games.
  fileSystems."/srv/gamesaves" = {
    device = "vault/gamesaves";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };

  # The files area (myServices.filebrowserQuantum): dataset vault/files on
  # the 4x 4TB mirrors. Create once: `zfs create -o mountpoint=legacy vault/files`.
  fileSystems."/srv/files" = {
    device = "vault/files";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };

  # Data moved from karma (karma-import.nix): one dataset per former Unraid
  # share on vault. Created 2026-11-26 with
  # `zfs create -o mountpoint=legacy vault/{home,trading,backup,setup,photos}`.
  fileSystems."/srv/home" = {
    device = "vault/home";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };
  fileSystems."/srv/trading" = {
    device = "vault/trading";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };
  fileSystems."/srv/backup" = {
    device = "vault/backup";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };
  fileSystems."/srv/setup" = {
    device = "vault/setup";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
  };
  fileSystems."/srv/photos" = {
    device = "vault/photos";
    fsType = "zfs";
    options = [ "nofail" "x-systemd.requires=zfs-import-vault.service" "x-systemd.after=zfs-import-vault.service" ];
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
