# Deploy repo-managed wallpapers into ~/Pictures/Wallpapers.
{ config, lib, inputs, ... }:

let
  cfg = config.userSettings.wallpapers;
in
{
  options.userSettings.wallpapers.enable =
    lib.mkEnableOption "deploy wallpapers from nixdots to ~/Pictures/Wallpapers";

  config = lib.mkIf cfg.enable {
    home.file."Pictures/Wallpapers" = {
      source = inputs.self + "/assets/wallpapers";
      recursive = true; # symlink files individually; keep the directory writable
    };
  };
}
