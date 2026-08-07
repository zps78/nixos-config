# ../../modules/apps/vscodium.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.vscodium.enable =
    lib.mkEnableOption "VSCodium";

  config = lib.mkIf config.myApps.vscodium.enable {

    let
      kdl = pkgs.vscode-utils.buildVscodeExtension {
        pname = "kdl";
        version = "2.1.3";

        src = pkgs.fetchurl {
          url = "https://open-vsx.org/api/v1hz/kdl/2.1.3/file/v1hz.kdl-2.1.3.vsix";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };

        vscodeExtPublisher = "v1hz";
        vscodeExtName = "kdl";
        vscodeExtUniqueId = "v1hz.kdl";
      };
    in {
      programs.vscodium = {
        enable = true;

        profiles.default.extensions =
          (with pkgs.vscode-extensions; [
            enkia.tokyo-night
            esbenp.prettier-vscode
            jeff-hykin.better-nix-syntax
          ]
        )
          ++ [ kdl ];
      };

    }

  );
}
