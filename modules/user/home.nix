# Home Manager entry point for a user.
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.noctalia.homeModules.default

    ./default.nix
  ];

  home.stateVersion = "26.05";
  home.username = config.userSettings.name;
  home.homeDirectory = "/home/${config.userSettings.name}";
}
