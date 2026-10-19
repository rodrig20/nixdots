# Stylix user theming from a fixed base16 scheme (shared, see lib/stylix-theme.nix).
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.userSettings.stylix;
  theme = import ../../../lib/stylix-theme.nix;
in
{
  options.userSettings.stylix.enable = lib.mkEnableOption "Stylix theming (fixed palette)";

  config = lib.mkIf cfg.enable {
    dconf.enable = true;
    dconf.settings."org/gnome/desktop/interface" = {
      accent-color = theme.accentColor;
    };

    stylix = {
      enable = true;

      base16Scheme = theme.scheme;

      polarity = theme.polarity;

      fonts = theme.fonts pkgs;

      cursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 30;
      };

      targets.noctalia = {
        enable = true;
        opacity.enable = false;
        image.enable = false;
      };

      targets.gtk.enable = true;
      targets.qt.enable = true;
      targets.ghostty.enable = true;
      targets.hyprland.enable = true;
      targets.opencode.enable = true;
      targets.vesktop.enable = true;
      targets.micro.enable = true;
      targets.yazi.enable = true;
      targets.firefox.enable = true;
      targets.zen-browser = {
        enable = true;
        profileNames = [ "default" ];
      };
      targets.btop.enable = true;
      targets.vscode.enable = true;
      targets.mpv.enable = true;
      targets.neovim.enable = true;
    };

    # Stylix owns the cursor theme/size; hyprcursor format is still ours.
    home.pointerCursor.hyprcursor = {
      enable = true;
      size = 30;
    };
  };
}
