{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.widget = {
    battery = {
      display_mode = "graphic";
    };

    brightness = {
      show_label = false;
    };

    control-center = {
      glyph = "snowflake";
    };

    input_volume = {
      show_label = false;
    };

    media = {
      album_art_only = true;
      hide_when_no_media = true;
    };

    network = {
      show_label = false;
    };

    output_volume = {
      show_label = false;
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