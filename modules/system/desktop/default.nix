# Desktop environment: Hyprland (Wayland compositor) + GDM + portals.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.desktop;
in
{
  options.systemSettings.desktop.enable = lib.mkEnableOption "desktop (Hyprland + GDM + portals)";

  config = lib.mkIf cfg.enable {
    # Required by GDM
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;

    # File manager trash support, MTP, etc.
    services.gvfs.enable = true;

    # Privilege escalation UI
    security.polkit.enable = true;

    environment.sessionVariables = {
      # Chromium/Electron Wayland support
      NIXOS_OZONE_WL = "1";
      # Input method for GTK apps
      GTK_IM_MODULE = "gtk-im-context-simple";
    };

    programs.hyprland = {
      enable = true;
      # X11 app compatibility
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
      config.common.default = [ "hyprland" ];
    };
  };
}
