# ffmpeg, multimedia processing CLI.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.ffmpeg;
in
{
  options.userSettings.programs.ffmpeg.enable = lib.mkEnableOption "ffmpeg multimedia CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ffmpeg ];
  };
}
