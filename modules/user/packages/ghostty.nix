# Ghostty terminal emulator.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.ghostty;
in
{
  options.userSettings.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal";

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        "font-size" = 16;

        # Ctrl/Alt + arrows move word by word. Zsh maps \e[b and \e[f
        # to backward-word/forward-word, but not the default xterm 1;5C/D
        # sequences that terminals send.
        keybind = [
          "ctrl+arrow_left=esc:b"
          "ctrl+arrow_right=esc:f"
          "alt+arrow_left=esc:b"
          "alt+arrow_right=esc:f"
          "alt+delete=esc:d"
        ];
      };
    };
  };
}
