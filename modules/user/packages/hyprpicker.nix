# hyprpicker, screen colour picker.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.hyprpicker;
in
{
  options.userSettings.programs.hyprpicker.enable = lib.mkEnableOption "hyprpicker (screen colour picker)";

  config = lib.mkIf cfg.enable {
    # NOTE: dependency of the `oldirtty/color_picker` Noctalia plugin
    # (see modules/user/packages/noctalia). The plugin's service shells out to
    # hyprpicker and copies the sampled colour to the clipboard.
    home.packages = [ pkgs.hyprpicker ];
  };
}