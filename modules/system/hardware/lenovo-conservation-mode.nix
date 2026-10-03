# Lenovo battery conservation mode: stops charging below 100%.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.hardware.conservation-mode;
in
{
  options.systemSettings.hardware.conservation-mode.enable =
    lib.mkEnableOption "Lenovo battery conservation mode";

  config = lib.mkIf cfg.enable {
    systemd.services.lenovo-conservation-mode = {
      description = "Enable Lenovo battery conservation mode";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig.Type = "oneshot";
      # The firmware keeps the flag across reboots, so this only repairs it if a BIOS update resets it.
      script = ''
        echo 1 > /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
      '';
    };
  };
}