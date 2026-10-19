# Fonts: packages only; default font families are owned by Stylix (user module).
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.fonts;
in
{
  options.systemSettings.fonts.enable = lib.mkEnableOption "system font packages";

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
    ];
  };
}
