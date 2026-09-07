{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.shell = {
    password_style = "random";
    polkit_agent = true;
    screen_time_enabled = true;

    settings_window_translucent = true;

    launcher.providers = {
      calculator.prefix = "c";
      emoji.prefix = "e";
      session.prefix = "s";
      wallpaper.prefix = "p";
      windows.prefix = "w";
    };

    panel = {
      clipboard_placement = "attached";
      launcher_placement = "attached";
      open_near_click_clipboard = true;
      polkit_placement = "attached";

      transparency_mode = "soft";
    };

    screen_corners = {
      enabled = true;
      size = 16;
    };
  };
}