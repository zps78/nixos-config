# flake.nix
{
  description = "multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

outputs = inputs@{ nixpkgs, home-manager, ... }:

    let
      system = "x86_64-linux";

      makeUser = userName: userFile: {
        home-manager.users.${userName} = import userFile;
        home-manager.extraSpecialArgs = { inherit inputs; };
      };

      mkHost = {
        hostname,
        users,
      }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules =
            [
              ./hosts/${hostname}/configuration.nix
#             ./modules/desktop/niri.nix
              home-manager.nixosModules.home-manager
              
              {
                nixpkgs.config.allowUnfree = true;

                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
              }
            ]
            ++ users;
        };

    in {
      nixosConfigurations = {

        kepler = mkHost {
          hostname = "kepler";
          users = [
            (makeUser "sc" ./home/sc.nix)
          ];
        };

        kimi = mkHost {
          hostname = "kimi";
          users = [
            (makeUser "gt" ./home/gt.nix)

            # easy to add later
            # (makeUser "john" ./home/john.nix)
          ];
        };

        krieger = mkHost {
          hostname = "krieger";
          users = [
            (makeUser "bb" ./home/bb.nix)
          ];
        };

        krugerrand = mkHost {
          hostname = "krugerrand";
          users = [
            (makeUser "zp" ./home/zp.nix)
          ];
        };

        kuro = mkHost {
          hostname = "kuro";
          users = [
            (makeUser "zp" ./home/zp.nix)
          ];
        };
      };
    };
}
