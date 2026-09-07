# btop: interactive system/process monitor.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.btop;
in
{
  options.systemSettings.btop.enable = lib.mkEnableOption "btop (system monitor)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.btop ];
  };
}
