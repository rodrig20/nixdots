# Stylix system theming: GDM greeter + package overlays.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.stylix;
in
{
  options.systemSettings.stylix.enable = lib.mkEnableOption "Stylix system theming (GDM + overlays)";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      base16Scheme = ../../../modules/user/stylix/github-purple.yaml;
      overlays.enable = true;
      targets.gnome.enable = true;
    };

    programs.dconf.profiles.gdm.databases = [
      {
        settings."org/gnome/desktop/interface" = {
          accent-color = "purple";
        };
      }
    ];
  };
}
