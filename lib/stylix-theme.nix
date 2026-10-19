# Shared Stylix palette (scheme + polarity + accent) for system, user and root.
rec {
  # Custom base16 scheme (see modules/user/stylix/github-purple.yaml).
  scheme = ../modules/user/stylix/github-purple.yaml;

  polarity = "dark";

  # GNOME accent matching base0D (purple) in the scheme above.
  accentColor = "purple";

  # Font roles shared by system (GDM/root) and user stylix modules.
  fonts = pkgs: {
    monospace = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    sansSerif = {
      name = "Inter Variable";
      package = pkgs.inter;
    };
    serif = {
      name = "Literata";
      package = pkgs.literata;
    };
    emoji = {
      name = "Noto Color Emoji";
      package = pkgs.noto-fonts-color-emoji;
    };
    sizes.terminal = 16;
  };
}
