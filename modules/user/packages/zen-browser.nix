# Zen Browser (Twilight channel).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.zen-browser;
in
{
  options.userSettings.programs.zen-browser.enable = lib.mkEnableOption "Zen Browser";

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;

      # Pre-install extensions from AMO on first start
      policies.ExtensionSettings =
        let
          mkInstalled = slug: privateBrowsing: {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
            installation_mode = "normal_installed";
          } // lib.optionalAttrs privateBrowsing { private_browsing = true; };
        in
        {
          # uBlock Origin
          "uBlock0@raymondhill.net" = mkInstalled "ublock-origin" true;
          # Dark Reader
          "addon@darkreader.org" = mkInstalled "darkreader" true;
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkInstalled "bitwarden-password-manager" false;
        };

      # Pin the uBlock icon to the main toolbar
      profiles.default.extensionButtons = {
        "nav-bar" = [ "uBlock0@raymondhill.net" ];
      };

    };

    # Alias `zen-browser` to the `zen-twilight` binary on PATH.
    home.packages = [
      (pkgs.writeShellScriptBin "zen-browser" ''
        exec zen-twilight "$@"
      '')
    ];
  };
}
