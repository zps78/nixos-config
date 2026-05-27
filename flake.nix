# flake.nix
{
  description = "multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sunshine.url = "github:LizardByte/Sunshine";
  };

  outputs = { self, nixpkgs, home-manager, sunshine, ... }:

    let
      system = "x86_64-linux";

      makeUser = userName: userFile: {
        home-manager.users.${userName} = import userFile;
      };

      mkHost = {
        hostname,
        users,
      }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          nixpkgs.config.allowUnfree = true;

          specialArgs = {
            inherit sunshine;
          };

          modules =
            [
              ./hosts/${hostname}/configuration.nix

              home-manager.nixosModules.home-manager

              {
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
            # (makeUser "alice" ./home/alice.nix)
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
      };
    };
}
