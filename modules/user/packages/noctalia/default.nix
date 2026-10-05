# Noctalia v5 desktop shell.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.noctalia;
in
{
  options.userSettings.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 desktop shell";

    plugins = {
      mirror.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "wl-screen-mirror plugin (output mirroring widget).";
      };
      warp.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Cloudflare Warp plugin (needs the warp-svc service and a registered client).";
      };
      colorPicker.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Color picker plugin.";
      };
      regionRecorder.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Region screen recorder plugin.";
      };
      ocr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "OCR plugin (grab text from the screen).";
      };
    };
  };

  imports = [
    ./bar.nix
    ./control-center.nix
    ./desktop-widgets.nix
    ./idle.nix
    ./lockscreen.nix
    ./session.nix
    ./shell.nix
    ./wallpaper.nix
    ./widgets.nix
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.noctalia = {
        enable = true;
        systemd.enable = true;

      settings = {
        accessibility = {
          ui_scale = 1.15;
        };

        audio = {
          enable_sounds = true;
        };

        location = {
          auto_locate = true;
        };

        notification = {
          background_opacity = 0.75;
          history_retention_hours = 48;
        };

        osd = {
          background_opacity = 0.75;
          scale = 1.1;
        };

        plugins = {
          enabled =
            lib.optionals cfg.plugins.mirror.enable [ "elijaharch/wl-screen-mirror" ]
            ++ lib.optionals cfg.plugins.warp.enable [ "levi/warp" ]
            ++ lib.optionals cfg.plugins.colorPicker.enable [ "oldirtty/color_picker" ]
            ++ lib.optionals cfg.plugins.regionRecorder.enable [ "h-jangra/region-recorder" ]
            ++ lib.optionals cfg.plugins.ocr.enable [ "fel/ocr" ];
          auto_update = "all";
        };

        # Plugin settings (base layer; GUI edits in settings.toml win).
        plugin_settings = {
          "fel/ocr" = {
            languages = "por+eng";
          };
        };

        theme = {
          templates = {
            builtin_ids = [ ];
            community_ids = [ ];
          };
        };
      };
    };
  }

    # Use per-tool modules so they keep their config and share a single store path.
    (lib.mkIf cfg.plugins.mirror.enable {
      userSettings.programs.wl-mirror.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.plugins.colorPicker.enable {
      userSettings.programs.hyprpicker.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.plugins.regionRecorder.enable {
      userSettings.programs.slurp.enable = lib.mkDefault true;
      userSettings.programs.ffmpeg.enable = lib.mkDefault true;
      userSettings.programs.wl-screenrec.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.plugins.ocr.enable {
      userSettings.programs.grim.enable = lib.mkDefault true;
      userSettings.programs.slurp.enable = lib.mkDefault true;
      userSettings.programs.tesseract.enable = lib.mkDefault true;
    })
  ]);
}
