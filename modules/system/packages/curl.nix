# Curl HTTP client.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.curl;
in
{
  options.systemSettings.curl.enable = lib.mkEnableOption "curl";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.curl ];
  };
}
