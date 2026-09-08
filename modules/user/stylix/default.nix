# Stylix user theming from a fixed base16 scheme.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.userSettings.stylix;
in
{
  options.userSettings.stylix.enable = lib.mkEnableOption "Stylix theming (fixed palette)";

  config = lib.mkIf cfg.enable {
    dconf.settings."org/gnome/desktop/interface" = {
      accent-color = "purple";
    };

    stylix = {
      enable = true;

      # Custom scheme (see ./github-purple.yaml). To use a built-in scheme
      # instead: "${inputs.tinted-schemes}/base16/<name>.yaml"
      # (or base24/<name>.yaml)
      base16Scheme = ./github-purple.yaml;

      polarity = "dark";

      targets.noctalia = {
        enable = true;
        opacity.enable = false;
        image.enable = false;
      };

      targets.gtk = {
        enable = true;
        extraCss = let
          c = config.lib.stylix.colors.withHashtag;
        in ''
          :root {
            --accent-bg-color: ${c.base0D};
            --accent-fg-color: ${c.base00};
            --accent-color: ${c.base0D};
          }
        '';
      };
      targets.qt.enable = true;
      targets.kde.enable = true;
      targets.ghostty.enable = true;
      targets.hyprland.enable = true;
      targets.opencode.enable = true;
      targets.micro.enable = true;
      targets.yazi.enable = true;
      targets.firefox.enable = true;
      targets.zen-browser = {
        enable = true;
        profileNames = [ "default" ];
      };
      targets.btop.enable = true;
    };
  };
}
