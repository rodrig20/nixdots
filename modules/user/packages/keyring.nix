# Keyring (gnome-keyring) + libnotify.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.keyring;
in
{
  options.userSettings.programs.keyring.enable = lib.mkEnableOption "keyring (gnome-keyring) + libnotify";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gnome-keyring pkgs.libnotify ];
  };
}