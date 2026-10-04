# Minimal Stylix profile for root (GTK/Qt) so sudo/polkit GUI apps match the user theme.
{ config, lib, ... }:

let
  theme = import ../../../lib/stylix-theme.nix;
in
lib.mkIf config.systemSettings.stylix.enable {
  home-manager.users.root = { config, ... }: {
    home.username = "root";
    home.homeDirectory = "/root";
    home.stateVersion = "26.05";

    dconf.enable = true;
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      accent-color = theme.accentColor;
    };

    stylix = {
      enable = true;
      # autoEnable off: only theme what root apps need.
      autoEnable = false;
      # Same palette as the main user, pinned even if the user customises theirs.
      base16Scheme = theme.scheme;
      polarity = theme.polarity;

      targets.gtk.enable = true;
      targets.qt.enable = true;
    };
  };
}
