# btop Stylix theming (binary installed system-wide).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.btop_stylix;
in
{
  options.userSettings.programs.btop_stylix.enable = lib.mkEnableOption "btop Stylix theming";

  config = lib.mkIf cfg.enable {
    programs.btop.enable = true;
    programs.btop.package = null;
  };
}