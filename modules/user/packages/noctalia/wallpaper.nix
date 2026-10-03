{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.wallpaper = {
    transition = [
      "disc"
      "honeycomb"
      "stripes"
      "wipe"
      "zoom"
    ];
    transition_on_startup = true;
  };
}