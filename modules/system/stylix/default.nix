# Stylix system theming: GDM greeter + package overlays + root GUI apps.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.systemSettings.stylix;
  theme = import ../../../lib/stylix-theme.nix;
in
{
  options.systemSettings.stylix.enable = lib.mkEnableOption "Stylix system theming (GDM + overlays + root apps)";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      # Shared palette, see lib/stylix-theme.nix.
      base16Scheme = theme.scheme;
      polarity = theme.polarity;
      overlays.enable = true;
      targets.gnome.enable = true;
      targets.plymouth.enable = true;
      # System-wide GTK/Qt for root GUI apps; HM-only targets live in ./root.nix.
      targets.gtk.enable = true;
      targets.qt.enable = true;
    };

    # Required by stylix's GTK NixOS target.
    programs.dconf.enable = true;

    programs.dconf.profiles.gdm.databases = [
      {
        settings."org/gnome/desktop/interface" = {
          accent-color = theme.accentColor;
        };
      }
    ];
  };
}
