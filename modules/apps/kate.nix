# ../../modules/apps/kate.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.kate.enable =
    lib.mkEnableOption "Kate";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.kate.enable {
    home.packages = with pkgs; [
      clang-tools
      kdePackages.kate
      marksman
      nil
    ];
    xdg.dataFile."org.kde.syntax-highlighting/syntax/kdl.xml".source =
      pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/larsgw/katepart-kdl/main/kdl.xml";
        hash = "sha256-Hb0lChLsRstZQ02I1A/J7KWQ6OISMw7ji3zUNGWONu4=";
      };
  };
}
