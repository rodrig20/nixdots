# Options for userSettings.programs.rclone.
# enable/mountPoint are set in the host configuration.nix; config/secrets
# live in catalog.nix; default.nix consumes both.
{ lib, ... }:

{
  options.userSettings.programs.rclone = {
    enable = lib.mkEnableOption "rclone (cloud remotes + auto-mount)";

    remotes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "this remote (disabled by default)";

            mountPoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                If set (and enable = true), auto-mount the root of this
                remote to this path via a systemd user service on login.
                null = remote only appears in rclone.conf (no auto-mount).
              '';
              example = "/home/rodri/gdrive";
            };

            config = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.nullOr (lib.types.oneOf [
                  lib.types.bool
                  lib.types.int
                  lib.types.float
                  lib.types.str
                ])
              );
              default = { };
              description = ''
                Non-secret remote config (type, scope, host, ...).
                Keys follow rclone naming: hyphens → underscores, lowercase.
              '';
              example = {
                type = "drive";
                scope = "drive";
              };
            };

            secrets = lib.mkOption {
              type = lib.types.attrsOf lib.types.path;
              default = { };
              description = ''
                Mapping of rclone config key → path to the encrypted .age file.
                Registered as agenix secret <basename> (see default.nix) and
                resolved to ''${XDG_RUNTIME_DIR}/agenix/<basename>.
              '';
              example = {
                token = ../../../../secrets/rclone-gdrive-token.age;
                client_secret = ../../../../secrets/rclone-gdrive-client-secret.age;
              };
            };

            mountOptions = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.nullOr (lib.types.oneOf [
                  lib.types.bool
                  lib.types.int
                  lib.types.float
                  lib.types.str
                ])
              );
              default = { };
              description = ''
                Extra rclone mount flags (Home Manager applies cache defaults).
                Set in configuration.nix only if the defaults are not enough.
              '';
            };
          };
        }
      );

      # A non-empty `default` (priority 1500) is discarded as soon as the host
      # sets any remote (priority 100); the catalogue lives in catalog.nix
      # (config), which merges equal-to-equal.
      default = { };

      description = ''
        Declarative rclone remotes. Known remotes ship pre-configured in
        the catalogue (catalog.nix); configuration.nix only enables each
        remote and picks its mountPoint.
      '';
      example = lib.literalExpression ''
        {
          gdrive = {
            enable = true;
            mountPoint = "/home/rodri/gdrive";
          };
        }
      '';
    };
  };
}
