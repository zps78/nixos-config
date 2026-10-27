# ../../modules/apps-user/minecraft.nix
#
# Minecraft has no Steam listing and no standalone Nix package of its
# own (it's not FOSS) - this installs Prism Launcher instead, the
# actively-maintained community launcher (mod/instance management,
# account login, per-instance Java/version pinning). It fetches the
# actual game assets/jars at first run under the user's own Microsoft
# account, same as the official launcher would.
{ config, pkgs, lib, ... }:

{
  options.myApps.minecraft.enable =
    lib.mkEnableOption "Minecraft (via Prism Launcher)";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.minecraft.enable {
    home.packages = [
      pkgs.prismlauncher
    ];
  };
}
