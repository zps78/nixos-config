# ../../modules/desktop/yamis.nix
{ config, lib, pkgs, ... }:

let
  yamis = pkgs.stdenvNoCC.mkDerivation {
    pname = "yamis";
    version = "unstable-2026-08-13";

    src = pkgs.fetchgit {
      url = "https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git";
      rev = "a4cf21df7e3e4455b85d15145735557f";
      hash = lib.fakeHash;
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
