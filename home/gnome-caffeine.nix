# ../../home/gnome-caffeine.nix
#
# Caffeine: a quick-settings toggle (coffee cup) that keeps GNOME from
# blanking the screen and suspending on idle - the GNOME counterpart of
# Noctalia's caffeine button on the niri hosts. Useful when work happens
# over SSH (a long nixos-rebuild): GNOME doesn't count SSH activity, so
# its idle-suspend would otherwise put the machine to sleep mid-job.
#
# It blocks GNOME's *idle* suspend only. Closing the lid still suspends
# (logind's HandleLidSwitch); for that, run the job under
#   sudo systemd-inhibit --what=sleep:idle:handle-lid-switch <command>
#
# Supports shell-version 45-51 (checked 2026-11-19 against GNOME 51.1).
# Defaults kept; tweak in the extension's preferences.
{ pkgs, ... }:

{
  programs.gnome-shell.extensions = [
    { package = pkgs.gnomeExtensions.caffeine; }
  ];
}
