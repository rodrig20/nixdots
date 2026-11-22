# NixYo host configuration.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.pc = import ./hardware/nixyo.nix;

  # Where the hibernation image is written and read back from (NixOS passes it
  # as resume= on the kernel command line). Must be the disk swap: without it
  # the kernel picks the highest-priority swap device, which is zram
  # (RAM-backed), and hibernation fails.
  boot.resumeDevice = "/dev/disk/by-uuid/7ed562f5-e189-43c6-985c-584b974881fe";

  systemSettings = {
    btrfs.enable = true;
    fuse.allowOther = true;
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
      clean.enable = true;
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
              vfs-cache-mode = "full";
              vfs-cache-max-age = "1h";
              vfs-cache-max-size = "4G";
              vfs-write-back = "5s";
              vfs-read-chunk-streams = 4;
              dir-cache-time = "1h";
              poll-interval = "1m";
              umask = "0002";
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
              dir-cache-time = "1h";
              poll-interval = "1m";
              umask = "0002";
            };
          };
        };
      };
    };
    xdg.enable = true;
    stylix.enable = true;
  };
}
