# ../../modules/system/auth.nix
{ config, lib, ... }:

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
    greetd.fprintAuth = false; # Hyprland / Niri setups

    ############################################################
    # Sudo
    ############################################################
    sudo.fprintAuth = true;

    ############################################################
    # Screen lockers (important for Wayland setups)
    ############################################################
    swaylock.fprintAuth = false;
    hyprlock.fprintAuth = false;

    # If you use other lockers later, add them here
  };
}