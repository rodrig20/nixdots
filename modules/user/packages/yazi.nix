# Yazi terminal file manager.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.yazi;
in
{
  options.userSettings.programs.yazi.enable = lib.mkEnableOption "yazi terminal file manager";

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
