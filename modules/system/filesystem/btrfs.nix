# Btrfs mount options: compression and atime behaviour.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.btrfs;

  # Installer-created subvolumes; /boot is vfat so it must be left out.
  btrfsMounts = [
    "/"
    "/home"
    "/nix"
  ];
in
{
  options.systemSettings.btrfs.enable = lib.mkEnableOption "btrfs mount options";

  config = lib.mkIf cfg.enable {
    fileSystems = lib.genAttrs btrfsMounts (_: {
      options = lib.mkAfter [
        "compress=zstd:3"
        "noatime"
      ];
    });
  };
}