# UEFI Secure Boot via Lanzaboote (requires systemSettings.boot.enable).
#
# One-time setup (keys are NOT created by Nix; they must exist before switch):
#   1. BIOS -> Secure Boot -> Clear keys / Setup Mode
#   2. sudo sbctl create-keys
#   3. sudo nixos-rebuild switch --flake /home/rodri/nixdots#<host>
#   4. sudo sbctl enroll-keys --microsoft
#   5. sbctl verify
#   6. BIOS -> Secure Boot -> Enabled (User mode)
#
# Backup /var/lib/sbctl somewhere safe. Recovery if it breaks:
# BIOS -> Secure Boot -> Disabled.
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.systemSettings.boot.secureboot;
in
{
  options.systemSettings.boot.secureboot.enable =
    lib.mkEnableOption "UEFI Secure Boot via Lanzaboote";

  # Imports cannot be conditional, so the module is always imported;
  # it only activates when boot.lanzaboote.enable is set below.
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  config = lib.mkIf cfg.enable {
    # Lanzaboote replaces systemd-boot.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      # Where `sbctl create-keys` put the PK/KEK/db keys (default location).
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = [ pkgs.sbctl ];
  };
}
