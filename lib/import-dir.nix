# Recursively import modules under a directory, excluding `default.nix`.
{ lib, dir, exclude ? [ "default.nix" ] }:

let
  getDir = dir: lib.mapAttrs
    (file: type:
      if type == "directory" then getDir "${dir}/${file}" else type
    )
    (builtins.readDir dir);

  files = dir: lib.collect lib.isString
    (lib.mapAttrsRecursive (path: type: lib.concatStringsSep "/" path) (getDir dir));
in
map (file: dir + "/${file}")
  (lib.filter
    (file: lib.hasSuffix ".nix" file && !(lib.elem file exclude))
    (files dir))
