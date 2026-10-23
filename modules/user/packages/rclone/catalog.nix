# Catalogue of known remotes: type, client_id and .age files per remote.
# Defined in config (priority 100) so it merges equal-to-equal with
# remotes.* from configuration.nix (enable / mountPoint on top).
# New remote: add the block here + a line in agenix-rules.nix (repo root).
{ ... }:

{
  userSettings.programs.rclone.remotes.gdrive = {
    config = {
      type = "drive";
      client_id = "392613051412-5mgdvgp0vee75is7ttkc07p70k2f14e0.apps.googleusercontent.com";
      scope = "drive";
      team_drive = "";
    };
    secrets = {
      token = ../../../../secrets/rclone-gdrive-token.age;
      client_secret = ../../../../secrets/rclone-gdrive-client-secret.age;
    };
  };
}
