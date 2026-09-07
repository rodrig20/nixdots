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

    home.shellAliases = {
      ls = "eza --icons=auto";
      ll = "eza -l --icons=auto";
      la = "eza -la --icons=auto";
      lt = "eza --tree --icons=auto";
      grep = "rg --smart-case";
      cat = "bat";
      # 'r' prefix bypasses the aliased replacements via `command`
      rls = "command ls";
      rgrep = "command grep";
      rcat = "command cat";
    };
  };
}
