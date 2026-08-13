# ../../modules/desktop/yamis.nix
{ lib, pkgs, ... }:

let
  yamis = pkgs.stdenvNoCC.mkDerivation {
    pname = "yamis";
    version = "unstable-2026-08-13";

    src = pkgs.fetchgit {
      url = "https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git";
      rev = "c5c3efe961e843b865d2b13b8180aff6ce64e496";
      hash = "sha256-1UrfH4AH2+tlFgc13X1nacaBzbucPeF8N/1m9gDDf30=";
    };

    installPhase = ''
      mkdir -p $out/share/icons/YAMIS
      cp -r ./* $out/share/icons/YAMIS/
    '';

    meta = {
      description = "Yet Another Monochrome Icon Set";
      homepage = "https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set";
      license = lib.licenses.gpl3Only;
    };
  };
in
{
  home.packages = [ yamis ];

  gtk.iconTheme = {
    package = yamis;
    name = "YAMIS";
  };
}
