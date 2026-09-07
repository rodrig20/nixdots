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
      auto-optimise-store = true;
      max-jobs = "auto";
    };

    # Lower IO priority for the nix daemon
    nix.daemonIOSchedPriority = 7;

    nixpkgs.config.allowUnfree = true;
  };
}
