# Rclone: declarative remotes + auto-mounts with agenix-managed credentials.
{ config, pkgs, lib, osConfig, ... }:

let
  cfg = config.userSettings.programs.rclone;

  # "rclone-gdrive-token.age" → "rclone-gdrive-token" (age.secrets key).
  secretName = file: lib.removeSuffix ".age" (builtins.baseNameOf file);
in
{
  imports = [
    ./catalog.nix
    ./options.nix
  ];

  # Rclone needs agenix enabled (credentials are .age files).
  # identityPaths are wired by modules/system/agenix.nix.
  config = lib.mkIf (cfg.enable && osConfig.systemSettings.agenix.enable) {
    home.packages = [ pkgs.rclone ];

    age.secrets = lib.listToAttrs (
      lib.concatLists (
        lib.mapAttrsToList (_: remote:
          lib.mapAttrsToList (_: file:
            lib.nameValuePair (secretName file) { file = file; }
          ) remote.secrets
        ) (lib.filterAttrs (_: remote: remote.enable) cfg.remotes)
      )
    );

    programs.rclone = {
      enable = true;
      remotes = lib.mapAttrs (_: remote: {
        config = remote.config;
        secrets = lib.mapAttrs (_: file:
          config.age.secrets.${secretName file}.path
        ) remote.secrets;
        mounts = lib.optionalAttrs (remote.mountPoint != null) {
          "" = {
            enable = true;
            mountPoint = remote.mountPoint;
            options = remote.mountOptions;
          };
        };
      }) (lib.filterAttrs (_: remote: remote.enable) cfg.remotes);
    };
  };
}
