# Shell configuration: zsh + starship + eza + ripgrep + fzf.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.shell;
in
{
  options.userSettings.shell.enable = lib.mkEnableOption "zsh shell config";

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      autocd = true;

      history = {
        size = 50000;
        save = 50000;
        share = true;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
      };

      initContent = ''
        # Make `/` a word separator
        WORDCHARS=''${WORDCHARS//\/}
        setopt interactivecomments

        # Alt+Shift variants of the above include slashes again (see ghostty.nix).
        backward-kill-word-with-slashes() {
          local WORDCHARS="''${WORDCHARS}/"
          zle backward-kill-word
        }
        kill-word-with-slashes() {
          local WORDCHARS="''${WORDCHARS}/"
          zle kill-word
        }
        zle -N backward-kill-word-with-slashes
        zle -N kill-word-with-slashes
        bindkey '^[[127;4u' backward-kill-word-with-slashes
        bindkey '^[[3;4~' kill-word-with-slashes

        backward-word-with-slashes() {
          local WORDCHARS="''${WORDCHARS}/"
          zle backward-word
        }
        forward-word-with-slashes() {
          local WORDCHARS="''${WORDCHARS}/"
          zle forward-word
        }
        zle -N backward-word-with-slashes
        zle -N forward-word-with-slashes
        bindkey '^[[1;4D' backward-word-with-slashes
        bindkey '^[[1;4C' forward-word-with-slashes
      '';
    };

    programs.starship = {
      enable = true;
    };

    programs.eza = {
      enable = true;
    };

    programs.ripgrep.enable = true;

    programs.bat = {
      enable = true;
    };

    programs.fzf = {
      enable = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    home.shellAliases = {
      ls = "eza --icons=auto";
      ll = "eza -l --icons=auto";
      la = "eza -la --icons=auto";
      lt = "eza --tree --icons=auto";
      grep = "rg --smart-case";
      cat = "bat";
      cd = "z";
      cdi = "zi";
      # 'r' prefix bypasses the aliased replacements via `command`
      rls = "command ls";
      rgrep = "command grep";
      rcat = "command cat";
      rcd = "command cd";
    };
  };
}
