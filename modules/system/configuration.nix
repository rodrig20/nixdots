# Shared base configuration for all hosts.
{ config, pkgs, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned

    # Temporarily fix opencode 2.2.5: nixos-unstable pinned a wrong node_modules
    # hash (https://github.com/NixOS/nixpkgs/issues/582673). Refreshes itself away
    # once nixos-unstable picks up the corrected hash.
    (final: prev: {
      opencode =
        let
          brokenHash = "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=";
        in
        if prev.opencode.node_modules.outputHash == brokenHash then
          prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs (_: {
              outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            });
          })
        else
          prev.opencode;
    })
  ];

  system.stateVersion = "26.05";
}
