# ../../modules/apps/vscodium.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.vscodium.enable =
    lib.mkEnableOption "VSCodium";

  config = lib.mkIf config.myApps.vscodium.enable {
    programs.vscodium =
      let
        customExtensions = [
          (pkgs.vscode-utils.buildVscodeExtension {
            pname = "kdl";
            version = "2.1.3";
            src = pkgs.fetchurl {
              url = "https://open-vsx.org/api/v1hz/kdl/2.1.3/file/v1hz.kdl-2.1.3.vsix";
              hash = "sha256-i5J4hXU3cOnFiPS+LZ0fIwwQo7hV0dueF0cPXUv25z0=";
            };
            vscodeExtPublisher = "v1hz";
            vscodeExtName = "kdl";
            vscodeExtUniqueId = "v1hz.kdl";
          })
        ];
      in {
        enable = true;
        profiles.default.extensions =
          (with pkgs.vscode-extensions; [
            enkia.tokyo-night
            esbenp.prettier-vscode
            jeff-hykin.better-nix-syntax
          ])
        ++ customExtensions;
      };
  };
}
