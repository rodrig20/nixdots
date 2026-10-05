{ config, pkgs, lib, ... }:

let
  pg = config.userSettings.noctalia.plugins;
in
lib.mkIf config.userSettings.noctalia.enable (lib.mkMerge [
  {
    programs.noctalia.settings = {
      bar = {
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
              ]
              ++ lib.optional pg.regionRecorder.enable "recorder"
              ++ lib.optional pg.ocr.enable "ocr"
              ++ lib.optional pg.colorPicker.enable "color_picker"
              ++ lib.optional pg.mirror.enable "mirror"
              ++ lib.optional pg.warp.enable "warp";
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
    };
  }

  # Overrides the plugin's own clicks (only when the plugin is on).
  (lib.mkIf pg.warp.enable {
    programs.noctalia.settings.widget.warp = {
      type = "levi/warp:warp";

      actions = {
        left = "exec noctalia msg plugin levi/warp:service all toggle;sleep 0.1;noctalia msg plugin levi/warp:service all refresh";
        right = "exec noctalia msg panel-toggle levi/warp:panel";
      };
    };
  })

  (lib.mkIf pg.colorPicker.enable {
    programs.noctalia.settings.widget.color_picker = {
      type = "oldirtty/color_picker:widget";

      actions = {
        left = "exec noctalia msg plugin oldirtty/color_picker:service all pick";
        right = "exec noctalia msg panel-toggle oldirtty/color_picker:panel";
      };
    };
  })

  # Region recorder: left = region select/record toggle, right = fullscreen/stop.
  (lib.mkIf pg.regionRecorder.enable {
    programs.noctalia.settings.widget.recorder = {
      type = "h-jangra/region-recorder:widget";
    };
  })

  # OCR: left = OCR selected region, right = OCR focused output.
  (lib.mkIf pg.ocr.enable {
    programs.noctalia.settings.widget.ocr = {
      type = "fel/ocr:ocr";
    };
  })
])
