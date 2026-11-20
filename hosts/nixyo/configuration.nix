# NixYo host configuration.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.pc = import ./hardware/nixyo.nix;

  systemSettings = {
    btrfs.enable = true;
    gparted.enable = true;
    boot = {
      enable = true;
      kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;
      secureboot.enable = true;
    };
    locale.enable = true;
    nix.enable = true;
    nh = {
      enable = true;
      flake = "/home/rodri/nixdots";
    };
    vim.enable = true;
    wget.enable = true;
    curl.enable = true;
    jq.enable = true;
    tldr.enable = true;
    btop.enable = true;
    pciutils.enable = true;
    unzip.enable = true;
    git.enable = true;
    networking = {
      enable = true;
      hostName = "nixyo";
      warp.enable = true;
    };
    audio.enable = true;
    users = {
      enable = true;
      name = "rodri";
      description = "Rodrigo";
      extraGroups = [ "networkmanager" "wheel" "render" "video" "audio" "dialout"];
    };
    hardware = {
      enable = true;
      conservation-mode.enable = true;
    };
    keyring.enable = true;
    gaze = {
      enable = true;
      camera = {
        rgb = "usb:174f:11b3";
        ir = "usb:174f:11b3";
        parallelCapture = "auto";
      };
      security.level = "high";
      liveness.enabled = true;
    };
    desktop.enable = true;
    stylix.enable = true;
    fonts.enable = true;
    virtualisation = {
      podman.enable = true;
      libvirt.enable = true;
    };
    ollama.enable = true;

    agenix.enable = true;
  };

  home-manager.users.rodri.userSettings = {
    name = "rodri";
    shell.enable = true;
    programs = {
      btop_stylix.enable = true;
      git = {
        enable = true;
        name = "rodrig20";
        email = "101592068+rodrig20@users.noreply.github.com";
      };
      micro.enable = true;
      neovim.enable = true;
      vscode.enable = true;
      ghostty.enable = true;
      tmux.enable = true;
      yazi.enable = true;
      zen-browser = {
        enable = true;
        uiScale = "1.05";
      };
      vesktop.enable = true;
      clipboard.enable = true;
      keyring.enable = true;
      opencode = {
        enable = true;
        useOllama = true;
      };
      antigravity-cli.enable = true;
      nautilus.enable = true;
      onlyoffice.enable = true;
      loupe.enable = true;
      mpv.enable = true;
      hydra.enable = true;
      pavucontrol.enable = true;
      fastfetch.enable = true;
      direnv.enable = true;
      hyprland.enable = true;
      nwg-displays.enable = true;
      noctalia.enable = true;
      rclone = {
        enable = true;
        # Remote pre-configured in the module
        remotes = {
          gdrive = {
            enable = true;
            mountPoint = "/home/rodri/Cloud/gdrive";
            mountOptions = {
              exclude = ".crypt";
              cache-dir = "/home/rodri/.cache/rclone/gdrive";
              vfs-cache-mode = "writes";
              vfs-cache-max-age = "1h";
              vfs-write-back = "5s";
            };
          };
          gcrypt = {
            enable = true;
            mountPoint = "/home/rodri/Cloud/gcrypt";
            mountOptions = {
              cache-dir = "/home/rodri/.cache/rclone/gcrypt";
              vfs-cache-mode = "writes";
              vfs-cache-max-age = "1h";
              vfs-write-back = "5s";
            };
          };
        };
      };
    };
    xdg.enable = true;
    stylix.enable = true;
  };
}
