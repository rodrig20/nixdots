# Hardware abstraction with vendor-specific CPU/GPU config.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.hardware;
in
{
  options.systemSettings.hardware.enable = lib.mkEnableOption "hardware configuration";

  options.hardware.pc = lib.mkOption {
    type = lib.types.submodule {
      options = {
        cpuVendor = lib.mkOption {
          type = lib.types.enum [ "intel" "other" ];
          description = "CPU vendor for hardware-specific config (intel, other)";
        };
        gpuVendor = lib.mkOption {
          type = lib.types.enum [ "igpu_intel" "other" ];
          description = "GPU vendor for hardware-specific config (igpu_intel, other)";
        };
      };
    };
    description = "Hardware vendor knobs for this PC";
  };

  imports = [
    ./cpu/intel.nix
    ./gpu/igpu_intel.nix
  ];

  config = lib.mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable = true;
    services.fwupd.enable = true;
    services.udisks2.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.fstrim.enable = true;
    zramSwap = {
      enable = true;
      memoryPercent = 40;
      priority = 100;
    };
  };
}
