{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.lockscreen_widgets = {
    enabled = false;
    schema_version = 2;

    widget_order = [
      "lockscreen-login-box@eDP-1"
    ];

    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };

    widget."lockscreen-login-box@eDP-1" = {
      type = "login_box";

      settings = {
        background_color = "surface_variant";
        background_opacity = 0.88;
        background_radius = 12.0;

        center_password_text = false;

        input_opacity = 1.0;
        input_radius = 6.0;

        layout = "regular";

        show_caps_lock = true;
        show_keyboard_layout = true;
        show_login_button = true;
        show_media = true;
        show_session_buttons = true;
        show_unlock_hint = true;
        show_weather = true;
      };
    };
  };
}