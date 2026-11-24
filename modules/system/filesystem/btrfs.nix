# Btrfs mount options: compression and atime behaviour.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.btrfs;

  # On disko hosts the mount options are declared in hosts/<name>/disko.nix,
  # which is the single source of truth for fileSystems. On hosts with a
  # generated hardware config, add the options to the btrfs mounts here
  # (/boot is vfat, so it must be left out).
  btrfsMounts = [ "/" "/home" "/nix" ];
in
{
  options.systemSettings.btrfs.enable = lib.mkEnableOption "btrfs mount options";

  config = lib.mkIf (cfg.enable && !config.systemSettings.disko.enable) {
    fileSystems = lib.genAttrs btrfsMounts (_: {
      options = lib.mkAfter [
        "compress=zstd:3"
        "noatime"
      ];
    });
  };
}