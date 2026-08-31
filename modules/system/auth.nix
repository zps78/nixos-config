# ../../modules/system/auth.nix
{ ... }:

{
  security.pam.services = {
    ############################################################
    # TTY login
    ############################################################
    login.fprintAuth = false;

    ############################################################
    # Display managers
    ############################################################
    sddm.fprintAuth = false;   # KDE
    gdm.fprintAuth = false;    # GNOME (safe even if unused)
    greetd.fprintAuth = false; # Niri setups

    ############################################################
    # Sudo
    ############################################################
    sudo.fprintAuth = true;

    ############################################################
    # Screen lockers (important for Wayland setups)
    ############################################################
    # If you use other lockers later, add them here
  };
}
