# OnlyOffice editors (Onlyoffice Desktopeditors).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.onlyoffice;
in
{
  options.userSettings.programs.onlyoffice.enable = lib.mkEnableOption "OnlyOffice editors";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.onlyoffice-desktopeditors ];
  };
}
