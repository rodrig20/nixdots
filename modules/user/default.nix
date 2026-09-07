# User modules auto-importer (gated via userSettings.<name>.enable).
{ lib, ... }:

{
  imports = import ../../lib/import-dir.nix {
    inherit lib;
    dir = ./.;
    exclude = [ "default.nix" "home.nix" ];
  };
}
