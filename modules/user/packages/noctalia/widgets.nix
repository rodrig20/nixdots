{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.widget = {
    battery = {
      display_mode = "graphic";
    };

    bluetooth = {
      actions = {
        left = "bluetooth-toggle";
        right = "panel-toggle control-center bluetooth";
      };
    };

    brightness = {
      show_label = false;

      actions = {
        scroll_down = "brightness-up";
        scroll_up = "brightness-down";
      };
    };

    control-center = {
      glyph = "snowflake";
    };

    input_volume = {
      show_label = false;

      actions = {
        left = "mic-mute";
        right = "panel-toggle control-center audio";
        scroll_down = "mic-volume-up";
        scroll_up = "mic-volume-down";
      };
    };

    media = {
      album_art_only = true;
      hide_when_no_media = true;
    };

    network = {
      show_label = false;

      actions = {
        left = "network-toggle";
        right = "panel-toggle control-center network";
      };
    };

    output_volume = {
      show_label = false;

      actions = {
        left = "volume-mute";
        right = "panel-toggle control-center audio";
        scroll_down = "volume-up";
        scroll_up = "volume-down";
      };
    };

    power_profile = {
      actions = {
        scroll_down = "power-cycle next";
        scroll_up = "power-cycle prev";
      };
    };

    sysmon = {
      stat = "cpu_temp";
      visualization = "none";
    };

    workspaces = {
      labels_only_when_occupied = true;
    };
  };
}