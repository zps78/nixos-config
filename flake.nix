# flake.nix
{
  description = "multi-host NixOS config with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

#    zen-browser = {
#      url = "github:youwen5/zen-browser-flake";
#      inputs.nixpkgs.follows = "nixpkgs";
#    };
  };

  outputs = inputs@{ nixpkgs, home-manager, stylix, ... }:
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
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
              {
                nixpkgs.config.allowUnfree = true;

                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.sharedModules = [
                  stylix.homeModules.stylix
                ];
              }
            ]
            ++ users;
        };

    in {
      nixosConfigurations = {

        kepler = mkHost {
          hostname = "kepler";
          users = [
            (makeUser "sc" ./home/users/sc.nix)
          ];
        };

        kimi = mkHost {
          hostname = "kimi";
          users = [
            (makeUser "gt" ./home/users/gt.nix)

            # easy to add later
            # (makeUser "john" ./home/john.nix)
          ];
        };

        krieger = mkHost {
          hostname = "krieger";
          users = [
            (makeUser "bb" ./home/users/bb.nix)
          ];
        };

        krugerrand = mkHost {
          hostname = "krugerrand";
          users = [
            (makeUser "zp" ./home/users/zp.nix)
          ];
        };

        kuro = mkHost {
          hostname = "kuro";
          users = [
            (makeUser "zp" ./home/users/zp.nix)
          ];
        };
      };
    };
}
