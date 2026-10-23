# Agenix settings: SSH identity used to decrypt .age secrets via Home Manager.
{ config, lib, ... }:

let
  cfg = config.systemSettings.agenix;
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
      example = "/home/user/.ssh/id_ed25519_agenix";
    };
  };

  # Home Manager decrypts with the agenix SSH key only.
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.systemSettings.users.name}.age.identityPaths = lib.mkForce [ cfg.identityPath ];
  };
}
