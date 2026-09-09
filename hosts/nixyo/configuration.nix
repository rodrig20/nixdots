# NixYo host configuration.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.pc = import ./hardware/nixyo.nix;

  systemSettings = {
    boot.enable = true;
    locale.enable = true;
    nix.enable = true;
    vim.enable = true;
    wget.enable = true;
    curl.enable = true;
    jq.enable = true;
    btop.enable = true;
    pciutils.enable = true;
    unzip.enable = true;
    git.enable = true;
    networking.enable = true;
    networking.hostName = "nixyo";
    audio.enable = true;
    users.enable = true;
    users.name = "rodri";
    users.description = "Rodrigo";
    users.extraGroups = [ "networkmanager" "wheel" "render" "video" "audio" ];
    hardware.enable = true;
    keyring.enable = true;
    desktop.enable = true;
    stylix.enable = true;
    fonts.enable = true;
    virtualisation.podman.enable = true;
  };

  home-manager.users.rodri.userSettings = {
    name = "rodri";
    shell.enable = true;
    programs.btop_stylix.enable = true;
    programs.git.enable = true;
    programs.git.name = "rodrig20";
    programs.git.email = "101592068+rodrig20@users.noreply.github.com";
    programs.micro.enable = true;
    programs.vscode.enable = true;
    programs.ghostty.enable = true;
    programs.yazi.enable = true;
    programs.zen-browser.enable = true;
    programs.clipboard.enable = true;
    programs.keyring.enable = true;
    programs.opencode.enable = true;
    programs.nautilus.enable = true;
    programs.onlyoffice.enable = true;
    programs.loupe.enable = true;
    programs.pavucontrol.enable = true;
    programs.fastfetch.enable = true;
    programs.direnv.enable = true;
    xdg.enable = true;
    theme.enable = true;
    stylix.enable = true;
    programs.hyprland.enable = true;
    noctalia.enable = true;
  };
}
