# Pavucontrol PulseAudio volume control.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.pavucontrol;
in
{
  options.userSettings.programs.pavucontrol.enable = lib.mkEnableOption "pavucontrol volume mixer";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.pavucontrol ];
  };
}
