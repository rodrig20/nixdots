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

    # Dedup store hardlinks weekly (NVMe, cheap).
    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      max-jobs = "auto";
      substituters = [
        "https://cache.nixos.org"
        "https://noctalia.cachix.org"
        "https://cache.xinux.uz"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
      ];
      connect-timeout = 5;
    };

    # Lower IO priority for the nix daemon
    nix.daemonIOSchedPriority = 7;

    nixpkgs.config.allowUnfree = true;
  };
}
