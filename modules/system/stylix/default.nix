# Stylix system theming: GDM greeter + package overlays.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.systemSettings.stylix;
in
{
  options.systemSettings.stylix.enable = lib.mkEnableOption "Stylix system theming (GDM + overlays)";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      # Custom scheme (same as the user-level one). To use a built-in scheme
      # instead: "${inputs.tinted-schemes}/base16/<name>.yaml"
      # (or base24/<name>.yaml)
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
