{ lib, inputs, ... }:
{
  flake-file.inputs.nix-prompt = {
    url = "github:nix-tricks/nix-prompt";
    flake = false;
  };
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-prompt = pkgs.stdenv.mkDerivation (
        let
          runtimeInputs = [
            pkgs.bash
            pkgs.git
          ];
        in
        {
          pname = "nix-prompt";
          version = "b3b9fd2";
          src = inputs.nix-prompt;
          buildInputs = [ pkgs.bash ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          inherit runtimeInputs;
          installPhase = ''
            mkdir -p $out/bin
            cp scripts/nixprompt.sh $out/bin/nixprompt.sh
            chmod +x $out/bin/nixprompt.sh
          '';
        }
      );
    };
  flake.homeModules.nix-prompt =
    {
      config,
      self',
      osConfig,
      ...
    }:
    {
      options = {
        rcouto.hm.nix-prompt.enable = lib.mkEnableOption "enables nix-prompt";
      };
      config =
        let
          cfg = config.rcouto.hm.nix-prompt;
        in
        lib.mkIf cfg.enable {
          warnings =
            if osConfig == null || osConfig.programs.git.prompt.enable == true then
              [ ]
            else
              [
                "Without programs.git.prompt.enable = true, git badging in nix-prompt won't work"
              ];
          programs.git.enable = true;
          programs.bash.initExtra = ''
            export PROMPT_DIRTRIM=2 # sets the number of trailing directory components
            export GIT_PS1_SHOWUNTRACKEDFILES=1 # controls the untracked files indicator
            export GIT_PS1_SHOWDIRTYSTATE=1 # controls the dirty state indicator displ
            source ${self'.packages.nix-prompt}/bin/nixprompt.sh
          '';
        };
    };

}
