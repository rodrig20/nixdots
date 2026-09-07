# Direnv: loads per-project environments (e.g. nix develop) into the current shell.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.direnv;
in
{
  options.userSettings.programs.direnv.enable = lib.mkEnableOption "direnv";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}