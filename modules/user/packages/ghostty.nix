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

        # Ctrl/Alt + setas movem palavra a palavra. O zsh mapeia \e[b e \e[f
        # para backward-word/forward-word, mas nao as sequencias xterm 1;5C/D
        # que os terminais enviam por omissao.
        keybind = [
          "ctrl+arrow_left=esc:b"
          "ctrl+arrow_right=esc:f"
          "alt+arrow_left=esc:b"
          "alt+arrow_right=esc:f"
        ];
      };
    };
  };
}
