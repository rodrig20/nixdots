# Default applications by MIME type.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.xdg;
in
{
  options.userSettings.xdg.enable = lib.mkEnableOption "xdg default applications";

  config = lib.mkIf cfg.enable {
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/plain" = [ "micro.desktop" ];
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

        "x-scheme-handler/http" = [ "zen-twilight.desktop" ];
        "x-scheme-handler/https" = [ "zen-twilight.desktop" ];
        "x-scheme-handler/file" = [ "zen-twilight.desktop" ];

        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
      };
    };
  };
}
