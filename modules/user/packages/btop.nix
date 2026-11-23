# btop enabled via user settings (binary installed system-wide).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.btop;
in
{
  options.userSettings.programs.btop.enable = lib.mkEnableOption "btop (system package + Stylix theme)";

  config = lib.mkIf cfg.enable {
    programs.btop.enable = true;
    programs.btop.package = null;
  };
}