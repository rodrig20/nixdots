# Boot loader (systemd-boot unless Lanzaboote/Secure Boot replaces it);
# the kernel is chosen per host.
{ config, lib, ... }:

let
  cfg = config.systemSettings.boot;
in
{
  options.systemSettings.boot = {
    enable = lib.mkEnableOption "silent boot (systemd-boot unless Secure Boot replaces it)";

    # Each host picks its own kernel; null keeps the NixOS default (pkgs.linuxPackages).
    kernelPackages = lib.mkOption {
      type = with lib.types; nullOr raw;
      default = null;
      example = lib.literalExpression "pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3";
      description = ''
        Kernel package set (`boot.kernelPackages`) used by this host.
        Leave as null to use the default NixOS kernel.
      '';
    };
  };

  config = lib.mkMerge [
    # The kernel choice is independent of the boot loader (works with grub too).
    (lib.mkIf (cfg.kernelPackages != null) {
      boot.kernelPackages = cfg.kernelPackages;
    })

    (lib.mkIf cfg.enable {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.configurationLimit = 10;

      boot.tmp.cleanOnBoot = true;

      # Splash screen + silent boot (Esc during boot shows details).
      boot.plymouth.enable = true;
      boot.consoleLogLevel = 0;
      boot.kernelParams = [
        "quiet"
        "boot.shell_on_fail"
        "udev.log_level=3"
        "rd.systemd.show_status=false"
      ];
    })
  ];
}
