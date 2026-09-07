{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.bar = {
    default = {
      background_opacity = 0.75;

      end = [
        "media"
        "group:g3"
        "group:g4"
        "group:g5"
        "group:g6"
      ];

      margin_ends = 50;
      scale = 1.5;

      start = [
        "group:g1"
        "group:g2"
        "tray"
      ];

      thickness = 36;

      capsule_group = [
        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          id = "g6";
          members = [
            "battery"
            "control-center"
          ];
          opacity = 1.0;
          padding = 6.0;
        }

        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          id = "g5";
          members = [
            "network"
            "bluetooth"
          ];
          opacity = 1.0;
          padding = 6.0;
        }

        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          id = "g4";
          members = [
            "brightness"
            "output_volume"
            "input_volume"
          ];
          opacity = 1.0;
          padding = 6.0;
        }

        {
          accordion = true;
          accordion_direction = "start";
          enabled = true;
          fill = "surface_variant";
          id = "g3";
          members = [
            "caffeine"
            "clipboard"
            "screenshot"
          ];
          opacity = 1.0;
          padding = 6.0;
        }

        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          id = "g2";
          members = [
            "sysmon"
            "power_profile"
          ];
          opacity = 1.0;
          padding = 6.0;
        }

        {
          accordion = false;
          enabled = true;
          fill = "surface_variant";
          id = "g1";
          members = [
            "launcher"
            "workspaces"
          ];
          opacity = 1.0;
          padding = 6.0;
        }
      ];
    };
  };
}