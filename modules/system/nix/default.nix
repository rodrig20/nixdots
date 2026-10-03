# Nix package manager settings: flakes, GC, store optimization.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.nix;
in
{
  options.systemSettings.nix.enable = lib.mkEnableOption "nix settings (flakes, GC, store)";

  config = lib.mkIf cfg.enable {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      max-jobs = "auto";
      substituters = [
        "https://cache.nixos.org"
        "https://noctalia.cachix.org"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };

    # Lower IO priority for the nix daemon
    nix.daemonIOSchedPriority = 7;

    nixpkgs.config.allowUnfree = true;
  };
}
