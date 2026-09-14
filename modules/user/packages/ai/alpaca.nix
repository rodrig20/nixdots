# Alpaca GTK4 chat client for Ollama.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.alpaca;
in
{
  options.userSettings.programs.alpaca.enable = lib.mkEnableOption "Alpaca chat client for Ollama";

  config = lib.mkIf cfg.enable {
    # NOTE: use "Ollama (External)" at http://127.0.0.1:11434 (Ctrl+I).
    # The default Managed instance spawns its own empty server on :11435.
    home.packages = [ pkgs.alpaca ];
  };
}
