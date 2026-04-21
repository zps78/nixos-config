{
  description = "multi-host NixOS config with Home Manager";

  inputs = {
    nix-prompt.url = "github:rcouto/nix-prompt.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-prompt, nixpkgs, home-manager, ... }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Home Manager user helper
      makeUser = userName: userFile: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit nix-prompt;
        };
        home-manager.backupFileExtension = "backup";
        home-manager.users.${userName} = import userFile;
      };
    in
    {
      nixosConfigurations = {

        # --------------------------
        # Host: krugerrand
        # --------------------------
        krugerrand = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/krugerrand/configuration.nix
            home-manager.nixosModules.home-manager
            (makeUser "zp" ./home/zp.nix)
          ];
        };

        # --------------------------
        # Host: krieger
        # --------------------------
        krieger = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/krieger/configuration.nix
            home-manager.nixosModules.home-manager
            (makeUser "mc" ./home/mc.nix)
          ];
        };

        # --------------------------
        # Host: kepler
        # --------------------------
        kepler = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/kepler/configuration.nix
            home-manager.nixosModules.home-manager
            (makeUser "sc" ./home/sc.nix)
          ];
        };

        # --------------------------
        # Host: krypton
        # --------------------------
        krypton = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/krypton/configuration.nix
            home-manager.nixosModules.home-manager
            (makeUser "steam" ./home/steam.nix)
          ];
        };
      };
    };
}
