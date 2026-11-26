# Libvirt + QEMU/KVM with virt-manager GUI (imperative VMs in /var/lib/libvirt).
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.virtualisation.libvirt;
in
{
  options.systemSettings.virtualisation.libvirt.enable =
    lib.mkEnableOption "libvirt + QEMU/KVM + virt-manager (imperative VMs with GUI)";

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    virtualisation.spiceUSBRedirection.enable = true;

    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      virtiofsd
    ];

    users.groups.libvirtd.members = [ config.systemSettings.users.name ];

    # Impermanence: imperative VMs/disks created with virt-manager live here
    # (see the module header).
    environment.persistence.${config.systemSettings.impermanence.persistentStoragePath} =
      lib.mkIf config.systemSettings.impermanence.enable {
        directories = [
          "/var/lib/libvirt"
          # Directory, not file: systemd-creds creates credential.secret (0400).
          "/var/lib/systemd"
        ];
      };
  };
}
