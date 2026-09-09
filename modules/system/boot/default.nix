# Boot loader with systemd-boot and CachyOS BORE LTO kernel.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.boot;
in
{
  options.systemSettings.boot.enable = lib.mkEnableOption "systemd-boot + CachyOS kernel";

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;

    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto;

    boot.tmp.cleanOnBoot = true;
  };
}
