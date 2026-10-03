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

        # Two-level word navigation: plain Alt stops at `/` (WORDCHARS
        # is trimmed in shell/default.nix), Alt+Shift covers whole paths
        # via custom zsh widgets bound to the sequences below.
        keybind = [
          "ctrl+arrow_left=esc:b"
          "ctrl+arrow_right=esc:f"
          "alt+arrow_left=esc:b"
          "alt+arrow_right=esc:f"
          "alt+shift+arrow_left=csi:1;4D"
          "alt+shift+arrow_right=csi:1;4C"
          "alt+delete=esc:d"
          "alt+shift+backspace=text:\\x1b[127;4u"
          "alt+shift+delete=csi:3;4~"
        ];
      };
    };
  };
}
