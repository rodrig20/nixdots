# VSCode (FHS build) GUI editor.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.vscode;
in
{
  options.userSettings.programs.vscode.enable = lib.mkEnableOption "VSCode GUI editor";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.vscode-fhs ];
  };
}
