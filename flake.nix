{
  description = "NixOS multi-machine configuration";

  # Binary caches for faster package downloads
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      hosts = builtins.filter (x: x != null) (
        map (name:
          if (builtins.readDir ./hosts).${name} == "directory" then name else null
        ) (builtins.attrNames (builtins.readDir ./hosts))
      );
    in
    {
      templates = {
        base = {
          path = ./templates/base;
          description = "Base project dev shell for compilers/parsers and general development";
        };
      };

      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = { inherit inputs; };

            modules = [
              (./hosts + "/${host}" + "/configuration.nix")

              ./modules/system

              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit inputs; };
              }

              inputs.stylix.nixosModules.stylix
            ];
          };
        }) hosts
      );
    };
}
