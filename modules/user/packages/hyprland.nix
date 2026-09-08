# Hyprland compositor dotfiles.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.hyprland;

  hyprdot = name: { content = ../../../config/hypr/${name}.lua; };
in
{
  options.userSettings.programs.hyprland.enable = lib.mkEnableOption "hyprland dotfiles";

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      package = pkgs.hyprland;
      systemd.enable = false;

      extraLuaFiles = {
        monitors = hyprdot "monitors";
        autostart = hyprdot "autostart";
        gestures = hyprdot "gestures";
        input = hyprdot "input";
        binds = hyprdot "binds";
        general = hyprdot "general";
        layouts = hyprdot "layouts";
        animations = hyprdot "animations";
      };
    };
  };
}
