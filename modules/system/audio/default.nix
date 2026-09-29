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

      wireplumber = {
        # Bluetooth auto-switch.
        extraScripts."bluetooth-autoswitch.lua" =
          builtins.readFile ./bluetooth-autoswitch.lua;

        extraConfig."49-bluetooth-autoswitch" = {
          "wireplumber.components" = [
            {
              name = "bluetooth-autoswitch.lua";
              type = "script/lua";
              provides = "custom.bluetooth-autoswitch";
            }
          ];
          "wireplumber.profiles" = {
            main = {
              "custom.bluetooth-autoswitch" = "required";
            };
          };
        };
      };
    };

    # Realtime scheduling for low-latency audio
    security.rtkit.enable = true;
  };
}
