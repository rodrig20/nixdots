# jq: JSON parsing/transformation command-line tool.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.jq;
in
{
  options.systemSettings.jq.enable = lib.mkEnableOption "jq (JSON parsing)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jq ];
  };
}
