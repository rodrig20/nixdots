# Vesktop, Discord client for Wayland (Vencord based).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.vesktop;
in
{
  options.userSettings.programs.vesktop.enable = lib.mkEnableOption "Vesktop (Discord)";

  config = lib.mkIf cfg.enable {
    # NOTE: the Stylix theme (stylix.targets.vesktop) is injected here.
    # Extra CSS goes in vencord.extraQuickCss, not in the Stylix target.
    programs.vesktop.enable = true;
  };
}
