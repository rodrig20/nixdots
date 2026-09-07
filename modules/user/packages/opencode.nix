# OpenCode AI coding agent.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.opencode;
in
{
  options.userSettings.programs.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
    };
  };
}
