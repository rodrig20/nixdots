# Hardware diagnosis tools: lspci, lsusb.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.pciutils;
in
{
  options.systemSettings.pciutils.enable = lib.mkEnableOption "pciutils + usbutils (lspci/lsusb)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pciutils
      usbutils
    ];
  };
}
