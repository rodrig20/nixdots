# Cursor and dark colour scheme.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.theme;
in
{
  options.userSettings.theme.enable = lib.mkEnableOption "cursor + dark colour scheme";

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 28;

      gtk.enable = true;

      hyprcursor = {
        enable = true;
        size = 28;
      };
    };

    dconf.enable = true;
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
