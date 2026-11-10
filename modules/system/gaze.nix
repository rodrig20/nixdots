# Gaze facial authentication: sudo + GDM face login, TPM keyring unlock.
#
# One-time setup (faces/keyring are NOT created by Nix; run after switch):
#   1. sudo nixos-rebuild switch --flake /home/rodri/nixdots#<host>
#   2. gaze enroll
#   3. sudo gaze keyring
#
# Until enrolled, sudo and GDM fall back to your password.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.systemSettings.gaze;

  system = pkgs.stdenv.hostPlatform.system;

  # WORKAROUND: gaze-zstd
  #   why:          nixpkgs' cargo-setup-hook sets ZSTD_SYS_USE_PKG_CONFIG=1, so
  #                 zstd-sys must link a system libzstd via pkg-config. Gaze's
  #                 packaging doesn't include one, so the unpatched build panics:
  #                 "The system library `libzstd` required by crate `zstd-sys`
  #                 was not found."
  #   issue:        -
  #   added:        2026-11-09 (f595775)
  #   remove-when:  gaze ships zstd in its buildInputs upstream (GunduLabs/gaze)
  #   test:         cd /home/rodri/nixdots && nix build --no-link "$(nix eval --impure --raw --expr 'let f = builtins.getFlake (toString ./.); in f.inputs.gaze.packages.x86_64-linux.gaze.drvPath')^out"
  #                 exit 1 = ainda é preciso; exit 0 = remover patchZstd por inteiro
  patchZstd = p: p.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zstd ];
  });
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

      # Patch packages for the zstd-sys pkg-config requirement (see patchZstd).
      package = patchZstd inputs.gaze.packages.${system}.gaze;
      gui = {
        package = patchZstd inputs.gaze.packages.${system}.gaze-gui;
      };

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
