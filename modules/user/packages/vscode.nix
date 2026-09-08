# VSCode (FHS build) GUI editor.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.vscode;
in
{
  options.userSettings.programs.vscode.enable = lib.mkEnableOption "VSCode GUI editor";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs;
      profiles.default.userSettings = lib.mkForce { };
    };
  };
}
