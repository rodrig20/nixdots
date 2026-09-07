# GNOME Nautilus file manager.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.nautilus;
in
{
  options.userSettings.programs.nautilus.enable = lib.mkEnableOption "Nautilus file manager";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nautilus ];
  };
}
