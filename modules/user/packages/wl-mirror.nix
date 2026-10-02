# wl-mirror, scales one output onto another (aspect ratio preserved).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.wl-mirror;
in
{
  options.userSettings.programs.wl-mirror.enable = lib.mkEnableOption "wl-mirror (scaled output mirroring)";

  config = lib.mkIf cfg.enable {
    # NOTE: dependency of the `elijaharch/wl-screen-mirror` Noctalia plugin
    # (see modules/user/packages/noctalia). It captures an output and paints it,
    # scaled, fullscreen on another output.
    home.packages = [ pkgs.wl-mirror ];
  };
}
