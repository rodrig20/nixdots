# Clipboard: cliphist + wl-clip-persist + wl-clipboard.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.clipboard;
in
{
  options.userSettings.programs.clipboard.enable = lib.mkEnableOption "clipboard (cliphist + wl-clip-persist + wl-clipboard)";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cliphist pkgs.wl-clip-persist pkgs.wl-clipboard ];
  };
}