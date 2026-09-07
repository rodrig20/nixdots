{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.control_center = {
    width = 800;

    shortcuts = [
      {
        type = "wifi";
      }

      {
        type = "bluetooth";
      }

      {
        type = "audio";
      }

      {
        type = "mic_mute";
      }

      {
        type = "caffeine";
      }

      {
        type = "power_profile";
      }
    ];
  };
}