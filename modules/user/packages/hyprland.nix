# Hyprland compositor dotfiles.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.hyprland;
  noctalia = config.userSettings.noctalia;

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
      }
      # Noctalia shell: only when the shell is enabled, and plugin binds only when their plugin is enabled.
      // lib.optionalAttrs noctalia.enable {
        "noctalia.noctalia" = hyprdot "noctalia/noctalia";
        "noctalia.noctalia-binds" = hyprdot "noctalia/noctalia-binds";
      }
      // lib.optionalAttrs (noctalia.enable && noctalia.plugins.colorPicker.enable) {
        "noctalia.noctalia-plugins.color-picker" = hyprdot "noctalia/noctalia-plugins/color-picker";
      }
      // lib.optionalAttrs (noctalia.enable && noctalia.plugins.mirror.enable) {
        "noctalia.noctalia-plugins.mirror" = hyprdot "noctalia/noctalia-plugins/mirror";
      }
      // lib.optionalAttrs (noctalia.enable && noctalia.plugins.regionRecorder.enable) {
        "noctalia.noctalia-plugins.region-recorder" = hyprdot "noctalia/noctalia-plugins/region-recorder";
      }
      // lib.optionalAttrs (noctalia.enable && noctalia.plugins.ocr.enable) {
        "noctalia.noctalia-plugins.ocr" = hyprdot "noctalia/noctalia-plugins/ocr";
      };
    };

    # xhost for the session autostart grant (root GUI apps on XWayland).
    home.packages = [ pkgs.xhost ];
  };
}
