# User account setup.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.users;
in
{
  options.systemSettings.users = {
    enable = lib.mkEnableOption "user account setup";
    name = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Primary user account username";
    };
    description = lib.mkOption {
      type = lib.types.str;
      default = "User";
      description = "Full name for the primary user";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "networkmanager" "wheel" ];
      description = "Extra groups for the primary user";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.shells = [ pkgs.zsh ];

    programs.zsh.enable = true;

    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.description;
      extraGroups = cfg.extraGroups;
      shell = pkgs.zsh;
    };
  };
}
