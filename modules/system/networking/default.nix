# Networking and SSH agent.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.networking;
in
{
  options.systemSettings.networking.enable = lib.mkEnableOption "networking (NetworkManager + SSH agent)";
  options.systemSettings.networking.hostName = lib.mkOption {
    type = lib.types.str;
    default = "nixos";
    description = "Network hostname for this machine";
  };

  config = lib.mkIf cfg.enable {
    networking.hostName = cfg.hostName;

    networking.networkmanager.enable = true;

    programs.ssh = {
      startAgent = true;
    };
  };
}
