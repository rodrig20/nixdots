# Session panel: the default actions plus Hibernate.
{ config, pkgs, lib, ... }:

lib.mkIf config.userSettings.noctalia.enable {
  programs.noctalia.settings.shell.session.actions = [
    {
      action = "lock";
      shortcut = "1";
    }

    {
      action = "logout";
      shortcut = "2";
    }

    {
      action = "lock_and_suspend";
      shortcut = "3";
    }

    {
      action = "command";
      label = "Hibernate";
      glyph = "bedtime";
      command = "systemctl hibernate";
      shortcut = "4";
    }

    {
      action = "reboot";
      shortcut = "5";
    }

    {
      action = "shutdown";
      variant = "destructive";
      shortcut = "6";
    }
  ];
}
