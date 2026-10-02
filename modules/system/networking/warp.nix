# Cloudflare WARP: warp-svc daemon + warp-cli.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.networking.warp;
in
{
  options.systemSettings.networking.warp.enable =
    lib.mkEnableOption "Cloudflare WARP client (warp-svc + warp-cli)";

  config = lib.mkIf cfg.enable {
    # Starts the warp-svc systemd service, opens the WARP UDP port and puts warp-cli in the system PATH.
    # One-time manual step after enabling: sudo warp-cli --accept-tos registration new
    services.cloudflare-warp.enable = true;
  };
}
