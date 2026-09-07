# Ghostty terminal emulator.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.ghostty;
in
{
  options.userSettings.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal";

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        "font-size" = 16;
      };
    };
  };
}
