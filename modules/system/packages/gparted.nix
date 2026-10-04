{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.gparted;
in
{
  options.systemSettings.gparted.enable = lib.mkEnableOption "GParted (Polkit-based launcher)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.gparted ];
  };
}