# Agenix settings: SSH identity used to decrypt .age secrets via Home Manager,
# plus the two system-level password hashes consumed by sysusers.
{ config, lib, inputs, ... }:

let
  cfg = config.systemSettings.agenix;
  user = config.systemSettings.users.name;
in
{
  options.systemSettings.agenix = {
    enable = lib.mkEnableOption "agenix (decrypt .age secrets via HM at login)";

    identityPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.systemSettings.users.name}/.ssh/id_ed25519_agenix";
      description = ''
        SSH private key used to decrypt .age files.
        The matching public key must be a recipient in agenix-rules.nix (repo root).
      '';
      example = "/home/user/.ssh/id_ed25519";
    };
  };

  # Imports cannot be conditional; the NixOS module only activates via age.* below.
  imports = [ inputs.agenix.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    home-manager.users.${user}.age.identityPaths = lib.mkForce [ cfg.identityPath ];

    # NixOS activation decrypts these with the persisted host key and/or the
    # user's agenix key. /etc/ssh host keys and /home are both persistent.
    age = {
      identityPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "${cfg.identityPath}"
      ];
      secrets = {
        nixyo-root-password = {
          file = ../../secrets/nixyo-root-password.age;
          owner = "root";
          group = "root";
          mode = "0400";
        };
        nixyo-rodri-password = {
          file = ../../secrets/nixyo-rodri-password.age;
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };
    };

    # Durable passwords: /etc/shadow lives on the wiped root subvolume, so a
    # hashedPasswordFile from the Nix store is required.
    users.users.root.hashedPasswordFile = config.age.secrets.nixyo-root-password.path;
    users.users.${user}.hashedPasswordFile = config.age.secrets.nixyo-rodri-password.path;
  };
}
