# Gwenview KDE image viewer.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.gwenview;
in
{
  options.userSettings.programs.gwenview.enable = lib.mkEnableOption "Gwenview image viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.kdePackages.gwenview ];
  };
}
