# Zen Browser (Twilight channel).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.zen-browser;
in
{
  options.userSettings.programs.zen-browser = {
    enable = lib.mkEnableOption "Zen Browser";

    uiScale = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "1.0";
      example = "1.5";
      description = "Zen UI + web content scale via layout.css.devPixelsPerPx.";
    };
  };

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
          # Portuguese (PT) spellcheck dictionary
          "pt-PT@dictionaries.addons.mozilla.org" = mkInstalled "european-portuguese-spellcheck" true;
        };

      # Pin the uBlock icon to the main toolbar
      profiles.default.extensionButtons = {
        "nav-bar" = [ "uBlock0@raymondhill.net" ];
      };

      # Brave Search as the default search engine.
      profiles.default.search = {
        force = true;
        default = "Brave";
        engines = {
          "Brave" = {
            urls = [
              {
                template = "https://search.brave.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://search.brave.com/favicon.ico";
            definedAliases = [ "@brave" ];
          };
        };
      };

      profiles.default.settings =
        {
          # Never auto-offer page translation (manual translation keeps working).
          "browser.translations.automaticallyPopup" = false;
          # Default spellcheck language.
          "spellchecker.dictionary" = "pt-PT";
        }
        // lib.optionalAttrs (cfg.uiScale != null) {
          # UI + web content scale (userSettings.programs.zen-browser.uiScale).
          "layout.css.devPixelsPerPx" = cfg.uiScale;
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
