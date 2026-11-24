# Declarative disk layout for nixyo. This is the single source of truth for
# fileSystems/swapDevices. No physical disk is hardcoded: pass the target disk
# at formatting time with `--argstr device /dev/disk/by-id/<id>` (disko forwards
# it to this function). The default is a deliberate placeholder: it keeps normal
# NixOS evaluation working, but fails loudly if someone runs the disko script
# without supplying a real device.
#
# Swap is sized as min(RAM, 32 GiB). Nix cannot read /proc/meminfo at eval time
# (procfs reports size 0), so the installer shell computes the RAM in GiB and
# passes it with `--argstr ramGb "$RAM_GB"`. Override the result explicitly with
# `--argstr swapSize 8G`. During pure flake evaluation this value is unused
# (disko scripts only run in the installer), hence the harmless fallback.
{ device ? "/dev/disk/by-id/DISKO_DEVICE"
, ramGb ? null
, swapSize ? null
, ...
}:

let
  ram = if ramGb == null then 0 else builtins.fromJSON ramGb;
  swapSizeForDisk =
    if swapSize != null then
      swapSize
    else if ram > 0 then
      "${toString (if ram > 32 then 32 else if ram < 1 then 1 else ram)}G"
    else
      "16G";

  btrfsContent = {
    type = "btrfs";
    # Overwrite any existing signature (fresh install).
    extraArgs = [ "-f" ];
    subvolumes = {
      # Root subvolume (recreated at boot when impermanence is enabled).
      root = {
        mountpoint = "/";
        mountOptions = [ "compress=zstd:3" "noatime" ];
      };
      persistent = {
        mountpoint = "/persistent";
        mountOptions = [ "compress=zstd:3" "noatime" ];
      };
      home = {
        mountpoint = "/home";
        mountOptions = [ "compress=zstd:3" "noatime" ];
      };
      nix = {
        mountpoint = "/nix";
        mountOptions = [ "compress=zstd:3" "noatime" ];
      };
    };
  };

in
{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = device;
        content = {
          type = "gpt";
          partitions = {
            EFI = {
              name = "EFI";
              label = "EFI";
              start = "1M";
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            swap = {
              name = "swap";
              label = "swap";
              size = swapSizeForDisk;
              content = {
                type = "swap";
                # Hibernation: disko sets boot.resumeDevice from this device.
                resumeDevice = true;
              };
            };
            root = {
              name = "root";
              label = "root";
              size = "100%";
              content = btrfsContent;
            };
          };
        };
      };
    };
  };
}
