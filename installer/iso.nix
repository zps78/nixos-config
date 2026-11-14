# ../../installer/iso.nix
#
# Fleet installer image, built from this repo so the installer's nix and
# nixpkgs match the hosts exactly (same flake.lock):
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
# then copy result/iso/*.iso onto the Ventoy stick.
#
# On top of NixOS's GNOME installer: flakes on, sshd started at boot with
# the fleet admin keys (install a new host remotely from kuro), basic tools,
# and a copy of this repo at /etc/nixos-config for offline reference.
# Install a host with:
#   sudo nixos-install --flake /etc/nixos-config#<host>   (or a fresh git clone)
{ lib, pkgs, inputs, ... }:

{
  networking.hostName = "nixos-installer";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
    rsync
    tmux
    gptfdisk
    parted
    cryptsetup
  ];

  # The installer image enables sshd but doesn't start it at boot; start it,
  # key-only (the live "nixos" user has no password).
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0omZkhZ//fafpUbFHlcFQyKY8UHIbaCzbD8PAkBsMv kuro-fleet-access"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsHK3x6UPpNqhnV0t+MMdMb1iuy1xDLBfFk1UL4TMa9 krugerrand-fleet-access"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtfmTdbElBJm6tYaO//5GFJPgmx7Tt2LASqbnt3VGYR kepler-fleet-access"
  ];

  # Snapshot of this repo (git-tracked files, secrets stay age-encrypted).
  environment.etc."nixos-config".source = inputs.self;

  # zstd builds much faster than the default xz for a small size cost.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
}
