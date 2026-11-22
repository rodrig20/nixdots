# Nix package manager settings: flakes, GC, store optimization.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.nix;
  # Derive the host settings from the flake's nixConfig to keep one definition.
  flakeConfig = import ../../../flake.nix;
  extraSubstituters = flakeConfig.nixConfig.extra-substituters;
  extraKeys = flakeConfig.nixConfig.extra-trusted-public-keys;
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
      substituters = extraSubstituters;
      trusted-public-keys = extraKeys;
      connect-timeout = 5;
    };

    # Lower IO priority for the nix daemon
    nix.daemonIOSchedPriority = 7;

    nixpkgs.config.allowUnfree = true;
  };
}
