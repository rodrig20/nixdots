# Baobab (GNOME) disk usage analyzer.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.baobab;
in
{
  options.userSettings.programs.baobab.enable = lib.mkEnableOption "Baobab disk usage analyzer";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.baobab ];
  };
}
