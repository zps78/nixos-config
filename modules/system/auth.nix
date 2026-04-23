# ../../modules/system/auth.nix
{ config, lib, ... }:

{
  security.pam.services = {
    # TTY login
    login.fprintAuth = false;

    # KDE display manager
    sddm.fprintAuth = false;

    # Hyprland setups (if used)
    greetd.fprintAuth = false;

    # Lockscreen (Hyprland)
    hyprlock.fprintAuth = false;

    # Sudo (allowed)
    sudo.fprintAuth = true;
  };
}
