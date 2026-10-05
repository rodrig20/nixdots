# wl-screenrec, high-performance Wayland screen recorder (screencopy, rootless).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.wl-screenrec;
in
{
  options.userSettings.programs.wl-screenrec.enable = lib.mkEnableOption "wl-screenrec (Wayland screen recorder)";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wl-screenrec ];
  };
}
