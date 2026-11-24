# Gate for hosts whose disk layout is declared by disko. Shared modules use it
# to avoid re-declaring options (e.g. btrfs mount options) that disko owns.
{ lib, ... }:

{
  options.systemSettings.disko.enable =
    lib.mkEnableOption "disko-managed disk layout (fileSystems/swapDevices from the host's disko.nix)";
}
