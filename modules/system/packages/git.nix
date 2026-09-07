# Git available system-wide (recovery TTY, admin).
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.git;
in
{
  options.systemSettings.git.enable = lib.mkEnableOption "git (system-wide)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.git ];
  };
}
