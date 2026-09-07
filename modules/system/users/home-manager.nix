# Wires Home Manager to the system user.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.users;
in
lib.mkIf cfg.enable {
  home-manager.users.${cfg.name} = {
    imports = [
      ../../../modules/user/home.nix
    ];

    userSettings.name = cfg.name;
  };
}
