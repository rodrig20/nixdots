# slurp, region selector for Wayland.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.slurp;
in
{
  options.userSettings.programs.slurp.enable = lib.mkEnableOption "slurp (Wayland region selector)";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.slurp ];
  };
}
