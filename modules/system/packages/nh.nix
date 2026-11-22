# nh: Nix helper with pre-activation diffs and generation management.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.nh;
in
{
  options.systemSettings.nh = {
    enable = lib.mkEnableOption "nh (Nix helper)";
    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Flake directory for NH_FLAKE (enables bare `nh os switch`).";
    };
    clean.enable = lib.mkEnableOption "periodic nh clean (replaces nix.gc.automatic)";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = cfg.flake;

      clean = {
        enable = cfg.clean.enable;
        # Preserves direnv GC roots; nix.gc.automatic is disabled while active.
        extraArgs = "--no-direnv --keep-since 4d --keep 3";
      };
    };
  };
}
