# System modules auto-importer (gated via systemSettings.<name>.enable).
{ lib, ... }:

{
  imports = import ../../lib/import-dir.nix { inherit lib; dir = ./.; };
}
