{
  description = "NixOS multi-machine configuration";

  # Binary caches for faster package downloads.
  # The nixdots key signs the cache published by publish-cache.yml; the localhost
  # substituter belongs to services.nixcache-proxy, so CI never reaches for a
  # proxy that only exists on NixOS hosts.
  nixConfig = {
    extra-substituters = [
      "https://cache.lantian.pub/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      "rodrig20-nixdots:PheRyVacx5PaOnubgBCXRjecrLEvXnlCmZYN/IPOEB4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gaze = {
      url = "github:GunduLabs/gaze/v0.5.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    # GHCR-backed binary cache, pinned to the rev lib/cache/ and proxy/ came from.
    nixcache-oci = {
      url = "github:cmspam/nixcache-oci/838bed6046ff2f0428b49485ebd07269cd0fc399";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tinted Themes (base16) scheme collection, shared with the Stylix input above
    tinted-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };

    # ADHD-friendly output style skill for OpenCode.
    i-have-adhd = {
      url = "github:ayghri/i-have-adhd/v0.4.1";
      flake = false;
    };

    # Official Anthropic agent skills collection. Pinned in flake.lock; update with `nix flake update anthropics-skills`.
    anthropics-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    # Prebuilt nix-index database for comma/nix-locate.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Google Antigravity CLI and apps
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix/v2.35.2-4585983447007232";
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

              inputs.impermanence.nixosModules.impermanence
              inputs.disko.nixosModules.disko
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "bak";
                home-manager.overwriteBackup = true;
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.sharedModules = [ inputs.agenix.homeManagerModules.default ];
              }

              inputs.stylix.nixosModules.stylix
              inputs.nix-index-database.nixosModules.default
            ];
          };
        }) hosts
      );
    };
}
