# Gaze facial authentication: sudo + GDM face login, TPM keyring unlock.
#
# One-time setup (faces/keyring are NOT created by Nix; run after switch):
#   1. sudo nixos-rebuild switch --flake /home/rodri/nixdots#<host>
#   2. gaze enroll
#   3. sudo gaze keyring
#
# Until enrolled, sudo and GDM fall back to your password.
{ config, lib, inputs, ... }:

let
  cfg = config.systemSettings.gaze;
in
{
  options.systemSettings.gaze.enable =
    lib.mkEnableOption "Gaze face authentication (sudo + GDM login, TPM keyring unlock)";

  # Imports cannot be conditional, so the module is always imported;
  # it only activates when services.gaze.enable is set below.
  imports = [ inputs.gaze.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.gaze = {
      enable = true;

      # Upstream default is [ "sudo" "polkit-1" ]; keep only sudo.
      pam.defaultServices = [ "sudo" ];

      # Nix owns the config; the mutableConfig default seeds once and never overwrites.
      mutableConfig = false;

      # A face match unseals the keyring password from the TPM, so the login keyring opens too.
      settings.storage = {
        encrypt_templates = true;
        unlock_gnome_keyring = true;
      };

      gnome = {
        # Installs the GNOME extension and wires face auth into the gdm greeter.
        enable = true;
        gdmFaceLogin = true;
        # Lock-screen face unlock is GNOME-only; irrelevant on Hyprland.
        enableForUsers = false;
      };
    };
  };
}
