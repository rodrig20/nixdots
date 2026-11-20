# nwg-displays, GUI output management (monitor layout).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.nwg-displays;
in
{
  options.userSettings.programs.nwg-displays.enable = lib.mkEnableOption "nwg-displays (monitor layout GUI)";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nwg-displays ];
  };
}
