# Zen Browser (Twilight channel).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.zen-browser;
in
{
  options.userSettings.programs.zen-browser.enable = lib.mkEnableOption "Zen Browser";

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };

    # Alias `zen-browser` to the `zen-twilight` binary on PATH.
    home.packages = [
      (pkgs.writeShellScriptBin "zen-browser" ''
        exec zen-twilight "$@"
      '')
    ];
  };
}
