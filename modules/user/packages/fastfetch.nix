# System info display, themed with the Stylix palette.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.fastfetch;

  stylixOn = config.userSettings.stylix.enable;

  c = config.lib.stylix.colors.withHashtag;

  logoColor = lib.optionalAttrs stylixOn {
    "1" = c.base0D;
    "2" = c.base0E;
  };

  displayColor = lib.optionalAttrs stylixOn {
    keys = c.base05;
    title = c.base0D;
  };

  percentColor = lib.optionalAttrs stylixOn {
    green = c.base0B;
    yellow = c.base0A;
    red = c.base08;
  };

  esc = builtins.fromJSON ''"\u001b"'';
in
{
  options.userSettings.programs.fastfetch.enable = lib.mkEnableOption "fastfetch";

  config = lib.mkIf cfg.enable {
    programs.fastfetch = {
      enable = true;

      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

        logo = {
          type = "builtin";
          height = 15;
          width = 30;

          padding = {
            top = 5;
            left = 3;
          };

          color = logoColor;
        };

        display = {
          color = displayColor;

          percent = {
            color = percentColor;
          };
        };

        modules = [
          "break"

          {
            type = "custom";
            format = "${esc}[90m┌──────────────────────Hardware──────────────────────┐";
          }

          { type = "host"; key = "󰌢  PC"; }
          { type = "cpu"; key = "│ ├󰻠 "; }
          { type = "gpu"; key = "│ ├󰍹 "; format = "{name} ({driver})"; }
          { type = "memory"; key = "│ ├󰑭 "; }
          { type = "disk"; key = "└ └󰋊 "; }

          {
            type = "custom";
            format = "${esc}[90m└────────────────────────────────────────────────────┘";
          }

          "break"

          {
            type = "custom";
            format = "${esc}[90m┌──────────────────────Software──────────────────────┐";
          }

          { type = "os"; key = "  OS"; }
          { type = "kernel"; key = "│ ├󰌽 "; }
          { type = "bios"; key = "│ ├󰖡 "; }
          { type = "packages"; key = "│ ├󰏗 "; }
          { type = "shell"; key = "│ ├󰞷 "; }
          { type = "terminal"; key = "│ ├󰆍 "; }

          {
            type = "custom";
            format = "│ │";
          }

          { type = "lm"; key = "│ ├󰍁 "; }
          { type = "wm"; key = "│ └󱂬 "; }

          {
            type = "custom";
            format = "${esc}[90m└────────────────────────────────────────────────────┘";
          }

          "break"

          {
            type = "custom";
            format = "${esc}[90m┌─────────────────Uptime / Age / DT──────────────────┐";
          }

          {
            type = "command";
            key = "│ ├󰶟  ";
            text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
          }

          {
            type = "uptime";
            key = "│ ├󰅐  ";
          }

          {
            type = "datetime";
            key = "└ └󰄉  ";
            format = "{day-pretty}-{month-pretty}-{year} {hour-pretty}:{minute-pretty}:{second-pretty}";
          }

          {
            type = "custom";
            format = "${esc}[90m└────────────────────────────────────────────────────┘";
          }

          {
            type = "colors";
            paddingLeft = 2;
            symbol = "circle";
          }
        ];
      };
    };
  };
}
