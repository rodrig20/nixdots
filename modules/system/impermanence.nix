# Impermanence with native btrfs roots: hosts/<name>/disko.nix declares the
# persistent subvolumes, and this module recreates the `root` subvolume on
# every boot. Everything not linked from /persistent is therefore ephemeral.
#
# Persistence is distributed: every module owns its own state and declares it
# only when both it and impermanence are enabled, i.e.
#   environment.persistence.${config.systemSettings.impermanence.persistentStoragePath}
#     = lib.mkIf config.systemSettings.impermanence.enable { ... };
# This module provides those options, the initrd wipe service and the base
# system state every host needs regardless of which service modules are active.
{ config, lib, pkgs, utils, ... }:

let
  cfg = config.systemSettings.impermanence;

  # Derived from the filesystems declared by disko: no UUID/device is duplicated
  # here. The btrfs partition hosting / also hosts /persistent.
  btrfsDevice = config.fileSystems."/".device;
in
{
  options.systemSettings.impermanence = {
    enable = lib.mkEnableOption "impermanence (ephemeral btrfs root, persistent data)";

    # Single source of truth for where modules link their state into; also the
    # mount point of the persistent subvolume (same name, e.g. subvol=persistent).
    persistentStoragePath = lib.mkOption {
      type = lib.types.str;
      default = "/persistent";
      description = "Persistent storage mount point impermanence modules link their state into";
    };
  };

  config = lib.mkIf cfg.enable {
    # The mount itself comes from disko; it only needs to be available early
    # enough for impermanence to link state into it during boot.
    fileSystems.${cfg.persistentStoragePath}.neededForBoot = true;

    # Move the old root aside (keeping old_roots for 30 days) and create a fresh
    # root subvolume before sysroot.mount. `after local-fs-pre.target` lets
    # resume from hibernation finish before touching btrfs.
    boot.initrd.systemd.services.wipe-root = {
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      wantedBy = [ "initrd.target" ];
      before = [ "sysroot.mount" ];
      requires = [ "${utils.escapeSystemdPath btrfsDevice}.device" ];
      after = [
        "${utils.escapeSystemdPath btrfsDevice}.device"
        "local-fs-pre.target"
      ] ++ lib.optional config.systemSettings.disko.luks.enable
        "systemd-cryptsetup@cryptroot.service";
      path = [
        pkgs.btrfs-progs
        pkgs.coreutils
        pkgs.findutils
        pkgs.util-linux
      ];
      script = ''
        mkdir -p /btrfs_tmp
        mount ${btrfsDevice} /btrfs_tmp
        trap 'umount /btrfs_tmp' EXIT

        # Keep the directory present even on a fresh disk, otherwise `find`
        # fails under `set -e` and the new root is never created.
        mkdir -p /btrfs_tmp/old_roots

        if [ -e /btrfs_tmp/root ]; then
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        # A failed cleanup must never prevent the new root from being created.
        find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30 \
          -exec btrfs subvolume delete --recursive {} + || true

        btrfs subvolume create /btrfs_tmp/root
      '';
    };

    environment.persistence.${cfg.persistentStoragePath} = {
      # Machine identity: a new one every boot would break udev rules,
      # DHCP leases matching and any service keyed on it.
      files = [
        "/etc/machine-id"
      ];

      directories = [
        "/var/log"
        # Declarative uid/gid maps for dynamically allocated ids.
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
      ];
    };
  };
}
