# Core user-module options shared across home-manager modules.
{ config, pkgs, lib, ... }:

{
  options.userSettings = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Home-manager username";
    };
  };
}
