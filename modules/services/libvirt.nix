# ../../modules/services/libvirt.nix
{ config, pkgs, lib, ... }:

{
  # ------------------------------------------------------------
  # Virtualization stack (KVM + QEMU + libvirt)
  # ------------------------------------------------------------

  virtualisation.libvirtd = {
    enable = true;

    # Optional but recommended for better performance
    qemu = {
      runAsRoot = false;

      # Enables TPM / UEFI / modern VM features if needed
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # ------------------------------------------------------------
  # Networking for VMs (NAT bridge support)
  # ------------------------------------------------------------

  networking.firewall.trustedInterfaces = [
    "virbr0"
  ];

  # ------------------------------------------------------------
  # User access to libvirt
  # ------------------------------------------------------------
  # IMPORTANT:
  # Do NOT hardcode users here in scalable setups.
  # Assign this per-host or per-user module.

  # Example (uncomment in host config):
  #
  # users.users.zp.extraGroups = lib.mkAfter [ "libvirtd" ];

  # ------------------------------------------------------------
  # Packages for VM management tools
  # ------------------------------------------------------------

  environment.systemPackages = with pkgs; [
#   libvirt           # already installed by virtualisation.libvirtd.enable = true;
    virt-manager      # GUI VM manager
    virt-viewer       # SPICE/VNC viewer
    virtiofsd         # file sharing with VMs
  ];
}
