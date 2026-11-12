# Gaze facial authentication: sudo + GDM face login, TPM keyring unlock.
#
# Cameras are set in configuration.nix (systemSettings.gaze.camera.*).
# gaze only accepts "primary", /dev/videoN or usb:VID:PID — /dev/v4l symlinks
# are refused for privileged capture. Both spectra share the same device here:
#   usb:174f:11b3 -> rgb: /dev/video0 (color), ir: /dev/video2 (mono 8-bit)
# Set either to "" to use the other alone.
#
# One-time setup (faces/keyring are not created by Nix):
#   1. sudo nixos-rebuild switch --flake /home/rodri/nixdots#<host>
#   2. gaze enroll
#   3. sudo gaze keyring
#
# Until enrolled, sudo and GDM fall back to the password.
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.systemSettings.gaze;

  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.systemSettings.gaze = {
    enable = lib.mkEnableOption "Gaze face authentication (sudo + GDM login, TPM keyring unlock)";

    camera = {
      rgb = lib.mkOption {
        type = lib.types.str;
        description = "RGB camera (primary, /dev/videoN or usb:VID:PID); \"\" disables it.";
      };

      ir = lib.mkOption {
        type = lib.types.str;
        description = "IR camera (primary, /dev/videoN or usb:VID:PID); \"\" disables it.";
      };

      parallelCapture = lib.mkOption {
        type = lib.types.enum [ "never" "auto" "always" ];
        default = "auto";
        description = "Parallel RGB + IR capture.";
      };
    };

    security = {
      level = lib.mkOption {
        type = lib.types.enum [ "low" "medium" "high" "maximum" "custom" ];
        default = "maximum";
        description = "Security level; maximum requires both cameras to match.";
      };
    };

    liveness = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Anti-spoofing checks.";
      };
    };
  };

  # Imports cannot be conditional, so the module is always imported;
  # it only activates when services.gaze.enable is set below.
  imports = [ inputs.gaze.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.gaze = {
      enable = true;

      package = inputs.gaze.packages.${system}.gaze;
      gui = {
        package = inputs.gaze.packages.${system}.gaze-gui;
      };

      # Upstream default is [ "sudo" "polkit-1" ]; keep only sudo.
      pam.defaultServices = [ "sudo" ];

      # Nix owns the config; the mutableConfig default seeds once and never overwrites.
      mutableConfig = false;

      # A face match unseals the keyring password from the TPM, so the login keyring opens too.
      settings = {
        storage = {
          encrypt_templates = true;
          unlock_gnome_keyring = true;
        };
        # Empty string disables a camera; both empty means password only.
        cameras = {
          rgb = cfg.camera.rgb;
          ir = cfg.camera.ir;
          parallel_capture = cfg.camera.parallelCapture;
        };
        security = {
          level = cfg.security.level;
        };
        liveness = {
          enabled = cfg.liveness.enabled;
        };
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
