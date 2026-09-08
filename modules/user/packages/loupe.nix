# Loupe (GNOME) image viewer.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.loupe;
in
{
  options.userSettings.programs.loupe.enable = lib.mkEnableOption "Loupe image viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.loupe ];
  };
}