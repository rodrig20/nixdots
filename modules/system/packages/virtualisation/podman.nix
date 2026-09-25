# Podman: rootless containers with Docker compatibility.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.virtualisation.podman;
in
{
  options.systemSettings.virtualisation.podman.enable =
    lib.mkEnableOption "podman rootless + docker compat";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune.enable = true;
    };

    virtualisation.containers.enable = true;

    environment.systemPackages = with pkgs; [
      podman-compose
      buildah
      skopeo
    ];

    users.users.${config.systemSettings.users.name}.autoSubUidGidRange = true;
  };
}
