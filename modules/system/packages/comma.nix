# comma: run nixpkgs binaries without installing them (`, <cmd>`).
{ config, lib, ... }:

let
  cfg = config.systemSettings.comma;
in
{
  options.systemSettings.comma.enable = lib.mkEnableOption "comma (run nixpkgs binaries without installing)";

  config = lib.mkIf cfg.enable {
    # Uses the prebuilt nix-index database from nix-index-database.
    programs.nix-index-database.comma.enable = true;
  };
}
