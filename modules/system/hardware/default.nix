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
          default = "other";
          description = "CPU vendor for hardware-specific config (intel, other)";
        };
        gpuVendor = lib.mkOption {
          type = lib.types.enum [ "igpu_intel" "other" ];
          default = "other";
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
    hardware.graphics.enable32Bit = true;

    # Dynamic linker stub for non-Nix binaries
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        libGL
        libx11
        libxcursor
        libxi
        libxinerama
        libxrandr
        libxxf86vm
      ];
    };
    services.fwupd.enable = true;
    services.udisks2.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # Physical power button
    services.logind.settings.Login = {
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";

      # Lid: suspend now, then hibernate once the delay below elapses.
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
    };

    # suspend-then-hibernate
    systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";

    services.fstrim.enable = true;
    zramSwap = {
      enable = true;
      memoryPercent = 40;
      priority = 100;
    };
  };
}
