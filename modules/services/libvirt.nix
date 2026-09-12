# ../../modules/services/libvirt.nix
{ config, lib, pkgs, ... }:

{
  options.myServices.libvirt.enable =
    lib.mkEnableOption "libvirt virtualization host";

  config = lib.mkIf config.myServices.libvirt.enable {
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
    # Follows myDesktop.primaryUser (the per-host "who uses this
    # machine" indirection) rather than a manually-toggled group entry
    # in each host's configuration.nix - not a hardcoded username, still
    # varies correctly per host.
    users.users.${config.myDesktop.primaryUser}.extraGroups = [ "libvirtd" ];

    # ------------------------------------------------------------
    # Packages for VM management tools
    # ------------------------------------------------------------

    environment.systemPackages = with pkgs; [
      virt-manager      # GUI VM manager
      virt-viewer       # SPICE/VNC viewer
      virtiofsd         # file sharing with VMs
    ];
  };
}
