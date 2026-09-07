# Vim system editor.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.vim;
in
{
  options.systemSettings.vim.enable = lib.mkEnableOption "vim";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.vim ];
  };
}
