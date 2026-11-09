# Shared base configuration for all hosts.
{ config, pkgs, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  system.stateVersion = "26.05";
}
