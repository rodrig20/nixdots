# Hyprland compositor dotfiles + generated Stylix-aware colors.lua.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.hyprland;
  stylixOn = config.stylix.enable or false;
  colors = if stylixOn then config.lib.stylix.colors.withHashtag else { };
in
{
  options.userSettings.programs.hyprland.enable = lib.mkEnableOption "hyprland dotfiles";

  config = lib.mkIf cfg.enable {
    xdg.configFile."hypr" = {
      source = ../../../config/hypr;
      recursive = true;
    };

    # Generated palette used by Lua config (require "colors")
    xdg.configFile."hypr/colors.lua".text = ''
      local colors = {
        active_border     = "${if stylixOn then colors.base0E else "#b392f0"}",
        inactive_border   = "${if stylixOn then colors.base03 else "#6a5ca0"}",
        background        = "${if stylixOn then colors.base00 else "#0d1117"}",
        text              = "${if stylixOn then colors.base05 else "#d1d5da"}",
      }
      return colors
    '';
  };
}
