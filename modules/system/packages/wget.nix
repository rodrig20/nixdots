# Wget download utility.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.wget;
in
{
  options.systemSettings.wget.enable = lib.mkEnableOption "wget";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wget ];
  };
}
