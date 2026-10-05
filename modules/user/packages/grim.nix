# grim, screenshot utility for Wayland.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.grim;
in
{
  options.userSettings.programs.grim.enable = lib.mkEnableOption "grim (Wayland screenshot utility)";

  config = lib.mkIf cfg.enable {
    # NOTE: dependency of the `fel/ocr` Noctalia plugin
    # (see modules/user/packages/noctalia). Captures the slurp-selected
    # region for tesseract.
    home.packages = [ pkgs.grim ];
  };
}
