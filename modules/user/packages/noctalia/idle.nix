{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.idle = {
    behavior_order = [
      "screen-off"
      "lock"
      "lock-and-suspend"
    ];

    behavior = {
      lock = {
        action = "lock";
        enabled = true;
        timeout = 330.0;
      };

      lock-and-suspend = {
        action = "lock_and_suspend";
        enabled = true;
        timeout = 900.0;
      };

      screen-off = {
        action = "screen_off";
        enabled = true;
        timeout = 300.0;
      };
    };
  };
}