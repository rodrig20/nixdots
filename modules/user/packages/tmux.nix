# Tmux: persistent terminal sessions (survive window close and SSH drops).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.tmux;
in
{
  options.userSettings.programs.tmux.enable = lib.mkEnableOption "tmux (persistent terminal multiplexer)";

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      prefix = "C-a";
      mouse = true;
      baseIndex = 1;
      keyMode = "vi";
      historyLimit = 50000;
      clock24 = true;
      escapeTime = 0;
      terminal = "tmux-256color";
      sensibleOnTop = true;
      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        resurrect
        continuum
        tmux-which-key
        prefix-highlight
      ];
      extraConfig = ''
        # Truecolor passthrough for Ghostty.
        set-option -sa terminal-features ",xterm-ghostty:RGB"

        # Intuitive splits that keep the current directory.
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # Reload config.
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"

        # Show PREFIX state in the status bar (prefix-highlight plugin).
        set -g status-right '#{prefix_highlight} | %a %Y-%m-%d %H:%M'

        # Auto-restore the last saved session on tmux start (continuum).
        set -g @continuum-restore 'on'
        # Save scrollback contents too (resurrect).
        set -g @resurrect-capture-pane-contents 'on'
      '';
    };
  };
}
