# System-level gnome-keyring: D-Bus activation + PAM unlock on login.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.keyring;
in
{
  options.systemSettings.keyring.enable = lib.mkEnableOption "gnome-keyring (system)";

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;

    # ssh-agent is already handled by programs.ssh.startAgent (networking module)
    services.gnome.gcr-ssh-agent.enable = false;
  };
}
