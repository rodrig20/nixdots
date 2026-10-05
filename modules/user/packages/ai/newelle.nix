# Newelle GTK4 AI assistant (Ollama + OpenRouter + vision).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.newelle;
in
{
  options.userSettings.programs.newelle.enable = lib.mkEnableOption "Newelle AI assistant";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.newelle ];
  };
}
