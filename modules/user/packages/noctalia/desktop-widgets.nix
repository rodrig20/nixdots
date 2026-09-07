{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.desktop_widgets = {
    schema_version = 2;

    widget_order = [
      "desktop-widget-0000000000000001"
      "desktop-widget-0000000000000002"
      "desktop-widget-0000000000000003"
    ];

    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };

    widget."desktop-widget-0000000000000001" = {
      box_height = 192.0;
      box_width = 496.0;
      cx = 1528.0;
      cy = 968.0;
      output = "eDP-1";
      placement_height = 1200.0;
      placement_width = 1920.0;
      rotation = 0.0;
      type = "clock";
    };

    widget."desktop-widget-0000000000000002" = {
      box_height = 96.0;
      box_width = 208.0;
      cx = 1672.0;
      cy = 770.800048828125;
      output = "eDP-1";
      placement_height = 1200.0;
      placement_width = 1920.0;
      rotation = 0.0;
      type = "weather";
    };

    widget."desktop-widget-0000000000000003" = {
      box_height = 0.0;
      box_width = 0.0;
      cx = 256.0;
      cy = 340.5;
      output = "eDP-1";
      placement_height = 1200.0;
      placement_width = 1920.0;
      rotation = 0.0;
      type = "fancy_audio_visualizer";

      settings = {
        background = false;
      };
    };
  };
}