# Micro terminal text editor.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.micro;
in
{
  options.userSettings.programs.micro.enable = lib.mkEnableOption "micro editor";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.micro ];
  };
}
