# PipeWire audio stack.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.audio;
in
{
  options.systemSettings.audio.enable = lib.mkEnableOption "audio (PipeWire)";

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Realtime scheduling for low-latency audio
    security.rtkit.enable = true;
  };
}
