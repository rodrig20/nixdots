# Archive extraction and creation: unzip, zip.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.unzip;
in
{
  options.systemSettings.unzip.enable = lib.mkEnableOption "unzip + zip";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unzip
      zip
    ];
  };
}
