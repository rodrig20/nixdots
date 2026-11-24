# Networking and SSH agent.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.networking;
in
{
  options.systemSettings.networking.enable = lib.mkEnableOption "networking (NetworkManager + SSH agent)";
  options.systemSettings.networking.hostName = lib.mkOption {
    type = lib.types.str;
    default = "nixos";
    description = "Network hostname for this machine";
  };

  config = lib.mkIf cfg.enable {
    networking.hostName = cfg.hostName;
    networking.usePredictableInterfaceNames = false;

    networking.networkmanager.enable = true;

    # Impermanence: Wi-Fi/Ethernet connections are created by hand (nmcli/GUI),
    # so they must survive the ephemeral root. Host keys are only persisted
    # once sshd is enabled somewhere; without the daemon they don't exist.
    environment.persistence.${config.systemSettings.impermanence.persistentStoragePath} =
      lib.mkIf config.systemSettings.impermanence.enable {
        directories = [ "/etc/NetworkManager/system-connections" ];
        files = lib.optionals config.services.openssh.enable [
          "/etc/ssh/ssh_host_ed25519_key"
          { file = "/etc/ssh/ssh_host_ed25519_key.pub"; method = "symlink"; }
          "/etc/ssh/ssh_host_rsa_key"
          { file = "/etc/ssh/ssh_host_rsa_key.pub"; method = "symlink"; }
        ];
      };

    programs.ssh = {
      startAgent = true;
    };
  };
}
