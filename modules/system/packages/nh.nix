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
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = cfg.flake;
    };
  };
}
