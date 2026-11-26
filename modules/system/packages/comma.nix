# comma: run nixpkgs binaries without installing them (`, <cmd>`).
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.comma;
in
{
  options.systemSettings.comma.enable = lib.mkEnableOption "comma (run nixpkgs binaries without installing)";

  config = lib.mkIf cfg.enable {
    # nix-index fornece a base de dados usada pelo comma para localizar comandos.
    programs.nix-index.enable = true;
    environment.systemPackages = [ pkgs.comma ];
  };
}
