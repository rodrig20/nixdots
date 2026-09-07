# Git, Delta and SSH configuration.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.git;
in
{
  options.userSettings.programs.git = {
    enable = lib.mkEnableOption "git config";
    name = lib.mkOption {
      type = lib.types.str;
      default = "me";
      description = "Git author name";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "me@example.com";
      description = "Git author email";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.git = {
      enable = true;

      settings = {
        user = {
          name = cfg.name;
          email = cfg.email;
        };

        core.editor = "micro";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings."*" = {
        # Add keys to ssh-agent automatically
        addKeysToAgent = "yes";
      };
    };
  };
}
