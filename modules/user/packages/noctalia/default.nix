# Noctalia v5 desktop shell.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.noctalia;
in
{
  options.userSettings.noctalia.enable = lib.mkEnableOption "Noctalia v5 desktop shell";

  imports = [
    ./bar.nix
    ./control-center.nix
    ./idle.nix
    ./lockscreen.nix
    ./shell.nix
    ./widgets.nix
  ];

  config = lib.mkIf cfg.enable {
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

        theme = {
          templates = {
            builtin_ids = [ ];
            community_ids = [ ];
          };
        };
      };
    };
  };
}
