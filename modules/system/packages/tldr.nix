# tldr: simplified, community-driven man pages.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.tldr;
in
{
  options.systemSettings.tldr.enable = lib.mkEnableOption "tldr (simplified man pages)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tldr ];
  };
}
