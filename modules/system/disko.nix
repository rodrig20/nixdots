# Gate for hosts whose disk layout is declared by disko. Shared modules use it
# to avoid re-declaring options (e.g. btrfs mount options) that disko owns.
#
# LUKS and TPM2 are per-host choices. Each host sets them in its own
# configuration.nix; the manual install reads the same options and forwards
# them to disko as --argstr luks / --argstr tpm2 (plus --argstr passwordFile).
{ config, lib, ... }:

let
  cfg = config.systemSettings.disko;
in
{
  options.systemSettings.disko = {
    enable = lib.mkEnableOption "disko-managed disk layout (fileSystems/swapDevices from the host's disko.nix)";

    luks = {
      enable = lib.mkEnableOption "LUKS encryption of the btrfs partition that holds root/persistent/home/nix";

      tpm2 = lib.mkEnableOption "TPM2 auto-unlock of the LUKS volume (requires luks.enable)";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.luks.tpm2 || cfg.luks.enable;
        message = "systemSettings.disko.luks.tpm2 requires systemSettings.disko.luks.enable";
      }
    ];

    # /dev/tpm* must exist before systemd-cryptsetup tries tpm2-device=auto.
    boot.initrd.availableKernelModules = lib.mkIf cfg.luks.tpm2 [
      "tpm"
      "tpm_crb"
      "tpm_tis"
    ];
  };
}
