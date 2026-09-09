# Fonts: Noto + emoji + Nerd Mono for icons/glyphs.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.fonts;
in
{
  options.systemSettings.fonts.enable = lib.mkEnableOption "system fonts + fontconfig defaults";

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
